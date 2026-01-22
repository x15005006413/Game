local skynet = require "skynet"
local logger = require "logger"
local timer = require "timer"
local cjson = require "cjson"

local _M = {}

-- 房间状态
local ROOM_STATE = {
    WAITING = 1,    -- 等待中
    PLAYING = 2,    -- 游戏中
    FINISHED = 3,   -- 已结束
}

-- 玩家状态
local PLAYER_STATE = {
    NOT_READY = 0,      -- 未准备
    READY = 1,          -- 已准备
    PLAYING = 2,        -- 游戏中
    OFFLINE = 3,        -- 离线
}

-- 房间数据
local rooms = {}            -- room_id -> room_info
local uid2room = {}         -- uid -> room_id
local room_inc_id = 0       -- 房间自增ID

-- 默认配置
local DEFAULT_CONFIG = {
    max_players = 4,        -- 最大玩家数
    min_players = 2,        -- 最小开始人数
    game_type = "default",  -- 游戏类型
    is_private = false,     -- 是否私密房间
    password = nil,         -- 房间密码
    auto_start = false,     -- 全员准备后自动开始
    room_timeout = 3600,    -- 房间超时时间(秒)
}

-- 生成房间ID
local function gen_room_id()
    room_inc_id = room_inc_id + 1
    return string.format("%d%04d", os.time() % 100000, room_inc_id % 10000)
end

-- 获取 ws_agent 服务地址
local function get_agent()
    return skynet.localname(".ws_agent")
end

-- 向玩家发送消息
local function send_to_player(uid, msg)
    local agent = get_agent()
    if agent then
        skynet.send(agent, "lua", "send_to_client", uid, msg)
    end
end

-- 向房间内所有玩家广播消息
local function broadcast_to_room(room_id, msg, exclude_uid)
    local room = rooms[room_id]
    if not room then return end

    for uid, _ in pairs(room.players) do
        if uid ~= exclude_uid then
            send_to_player(uid, msg)
        end
    end
end

-- 获取房间简要信息（用于列表展示）
local function get_room_brief(room)
    return {
        room_id = room.room_id,
        owner_uid = room.owner_uid,
        game_type = room.config.game_type,
        player_count = room.player_count,
        max_players = room.config.max_players,
        state = room.state,
        is_private = room.config.is_private,
        create_time = room.create_time,
    }
end

-- 获取房间详细信息
local function get_room_detail(room)
    local players = {}
    for uid, player in pairs(room.players) do
        table.insert(players, {
            uid = uid,
            seat_index = player.seat_index,
            state = player.state,
            join_time = player.join_time,
            is_owner = (uid == room.owner_uid),
        })
    end
    -- 按座位排序
    table.sort(players, function(a, b) return a.seat_index < b.seat_index end)

    return {
        room_id = room.room_id,
        owner_uid = room.owner_uid,
        config = {
            max_players = room.config.max_players,
            min_players = room.config.min_players,
            game_type = room.config.game_type,
            is_private = room.config.is_private,
            auto_start = room.config.auto_start,
        },
        state = room.state,
        players = players,
        player_count = room.player_count,
        create_time = room.create_time,
    }
end

-- 获取空闲座位
local function get_free_seat(room)
    local used_seats = {}
    for _, player in pairs(room.players) do
        used_seats[player.seat_index] = true
    end
    for i = 1, room.config.max_players do
        if not used_seats[i] then
            return i
        end
    end
    return nil
end

-- 检查是否全员准备
local function check_all_ready(room)
    if room.player_count < room.config.min_players then
        return false
    end
    for uid, player in pairs(room.players) do
        if uid ~= room.owner_uid and player.state ~= PLAYER_STATE.READY then
            return false
        end
    end
    return true
end

-- 房间超时检查
local function room_timeout_check(room_id)
    local room = rooms[room_id]
    if not room then return end

    -- 游戏中不超时
    if room.state == ROOM_STATE.PLAYING then
        room.timeout_timer = timer.timeout(room.config.room_timeout, room_timeout_check, room_id)
        return
    end

    -- 超时解散房间
    logger.info("room", "Room timeout, dismissing", "room_id:", room_id)
    _M.force_dismiss_room(room_id, "timeout")
end

-- 强制解散房间
function _M.force_dismiss_room(room_id, reason)
    local room = rooms[room_id]
    if not room then return end

    -- 通知所有玩家
    local msg = {
        pid = "s2c_room_dismissed",
        room_id = room_id,
        reason = reason or "dismissed",
    }
    broadcast_to_room(room_id, msg)

    -- 清理玩家映射
    for uid, _ in pairs(room.players) do
        uid2room[uid] = nil
    end

    -- 取消定时器
    if room.timeout_timer then
        timer.cancel(room.timeout_timer)
    end

    -- 删除房间
    rooms[room_id] = nil
    logger.info("room", "Room dismissed", "room_id:", room_id, "reason:", reason)
end

--------------------- 公开接口 ---------------------

function _M.init()
    logger.info("room", "Room manager initialized")
end

-- 创建房间
function _M.create_room(uid, room_config)
    -- 检查玩家是否已在房间中
    if uid2room[uid] then
        return {ok = false, err = "Already in a room"}
    end

    -- 合并配置
    local config = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        config[k] = v
    end
    if room_config then
        for k, v in pairs(room_config) do
            if DEFAULT_CONFIG[k] ~= nil then
                config[k] = v
            end
        end
    end

    -- 创建房间
    local room_id = gen_room_id()
    local room = {
        room_id = room_id,
        owner_uid = uid,
        config = config,
        state = ROOM_STATE.WAITING,
        players = {},
        player_count = 0,
        create_time = os.time(),
        timeout_timer = nil,
    }

    -- 房主加入房间
    room.players[uid] = {
        uid = uid,
        seat_index = 1,
        state = PLAYER_STATE.NOT_READY,
        join_time = os.time(),
    }
    room.player_count = 1

    -- 保存房间
    rooms[room_id] = room
    uid2room[uid] = room_id

    -- 设置超时定时器
    room.timeout_timer = timer.timeout(config.room_timeout, room_timeout_check, room_id)

    logger.info("room", "Room created", "room_id:", room_id, "owner:", uid)

    return {
        ok = true,
        room_id = room_id,
        room_info = get_room_detail(room),
    }
end

-- 加入房间
function _M.join_room(uid, room_id, password)
    -- 检查玩家是否已在房间中
    if uid2room[uid] then
        return {ok = false, err = "Already in a room"}
    end

    -- 检查房间是否存在
    local room = rooms[room_id]
    if not room then
        return {ok = false, err = "Room not found"}
    end

    -- 检查房间状态
    if room.state ~= ROOM_STATE.WAITING then
        return {ok = false, err = "Room is not waiting"}
    end

    -- 检查房间是否已满
    if room.player_count >= room.config.max_players then
        return {ok = false, err = "Room is full"}
    end

    -- 检查密码
    if room.config.is_private and room.config.password then
        if password ~= room.config.password then
            return {ok = false, err = "Wrong password"}
        end
    end

    -- 获取空闲座位
    local seat_index = get_free_seat(room)
    if not seat_index then
        return {ok = false, err = "No available seat"}
    end

    -- 加入房间
    room.players[uid] = {
        uid = uid,
        seat_index = seat_index,
        state = PLAYER_STATE.NOT_READY,
        join_time = os.time(),
    }
    room.player_count = room.player_count + 1
    uid2room[uid] = room_id

    -- 广播玩家加入
    local msg = {
        pid = "s2c_player_joined",
        room_id = room_id,
        player = {
            uid = uid,
            seat_index = seat_index,
            state = PLAYER_STATE.NOT_READY,
        },
        player_count = room.player_count,
    }
    broadcast_to_room(room_id, msg, uid)

    logger.info("room", "Player joined room", "uid:", uid, "room_id:", room_id)

    return {
        ok = true,
        room_info = get_room_detail(room),
    }
end

-- 离开房间
function _M.leave_room(uid)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        uid2room[uid] = nil
        return {ok = false, err = "Room not found"}
    end

    -- 游戏中不能离开
    if room.state == ROOM_STATE.PLAYING then
        return {ok = false, err = "Cannot leave during game"}
    end

    -- 移除玩家
    room.players[uid] = nil
    room.player_count = room.player_count - 1
    uid2room[uid] = nil

    -- 如果房间空了，解散房间
    if room.player_count <= 0 then
        _M.force_dismiss_room(room_id, "empty")
        return {ok = true}
    end

    -- 如果是房主离开，转让房主
    if uid == room.owner_uid then
        for new_owner_uid, _ in pairs(room.players) do
            room.owner_uid = new_owner_uid
            break
        end
        -- 通知新房主
        local owner_msg = {
            pid = "s2c_owner_changed",
            room_id = room_id,
            new_owner_uid = room.owner_uid,
        }
        broadcast_to_room(room_id, owner_msg)
    end

    -- 广播玩家离开
    local msg = {
        pid = "s2c_player_left",
        room_id = room_id,
        uid = uid,
        player_count = room.player_count,
    }
    broadcast_to_room(room_id, msg)

    logger.info("room", "Player left room", "uid:", uid, "room_id:", room_id)

    return {ok = true}
end

-- 解散房间
function _M.dismiss_room(uid)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        uid2room[uid] = nil
        return {ok = false, err = "Room not found"}
    end

    -- 只有房主能解散
    if uid ~= room.owner_uid then
        return {ok = false, err = "Only owner can dismiss room"}
    end

    _M.force_dismiss_room(room_id, "owner_dismissed")

    return {ok = true}
end

-- 踢出玩家
function _M.kick_player(uid, target_uid)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        return {ok = false, err = "Room not found"}
    end

    -- 只有房主能踢人
    if uid ~= room.owner_uid then
        return {ok = false, err = "Only owner can kick player"}
    end

    -- 不能踢自己
    if uid == target_uid then
        return {ok = false, err = "Cannot kick yourself"}
    end

    -- 检查目标是否在房间
    if not room.players[target_uid] then
        return {ok = false, err = "Target not in room"}
    end

    -- 游戏中不能踢人
    if room.state == ROOM_STATE.PLAYING then
        return {ok = false, err = "Cannot kick during game"}
    end

    -- 移除玩家
    room.players[target_uid] = nil
    room.player_count = room.player_count - 1
    uid2room[target_uid] = nil

    -- 通知被踢玩家
    send_to_player(target_uid, {
        pid = "s2c_kicked",
        room_id = room_id,
    })

    -- 广播玩家被踢
    local msg = {
        pid = "s2c_player_kicked",
        room_id = room_id,
        uid = target_uid,
        player_count = room.player_count,
    }
    broadcast_to_room(room_id, msg)

    logger.info("room", "Player kicked", "target:", target_uid, "by:", uid, "room_id:", room_id)

    return {ok = true}
end

-- 转让房主
function _M.transfer_owner(uid, target_uid)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        return {ok = false, err = "Room not found"}
    end

    -- 只有房主能转让
    if uid ~= room.owner_uid then
        return {ok = false, err = "Only owner can transfer"}
    end

    -- 不能转让给自己
    if uid == target_uid then
        return {ok = false, err = "Cannot transfer to yourself"}
    end

    -- 检查目标是否在房间
    if not room.players[target_uid] then
        return {ok = false, err = "Target not in room"}
    end

    -- 转让房主
    room.owner_uid = target_uid

    -- 广播房主变更
    local msg = {
        pid = "s2c_owner_changed",
        room_id = room_id,
        new_owner_uid = target_uid,
    }
    broadcast_to_room(room_id, msg)

    logger.info("room", "Owner transferred", "from:", uid, "to:", target_uid, "room_id:", room_id)

    return {ok = true}
end

-- 准备/取消准备
function _M.set_ready(uid, is_ready)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        return {ok = false, err = "Room not found"}
    end

    -- 只能在等待状态准备
    if room.state ~= ROOM_STATE.WAITING then
        return {ok = false, err = "Room is not waiting"}
    end

    local player = room.players[uid]
    if not player then
        return {ok = false, err = "Player not found"}
    end

    -- 房主不需要准备
    if uid == room.owner_uid then
        return {ok = false, err = "Owner does not need to ready"}
    end

    -- 设置准备状态
    player.state = is_ready and PLAYER_STATE.READY or PLAYER_STATE.NOT_READY

    -- 广播准备状态
    local msg = {
        pid = "s2c_player_ready",
        room_id = room_id,
        uid = uid,
        is_ready = is_ready,
    }
    broadcast_to_room(room_id, msg)

    -- 检查是否自动开始
    if room.config.auto_start and check_all_ready(room) then
        _M.start_game(room.owner_uid)
    end

    return {ok = true}
end

-- 开始游戏
function _M.start_game(uid)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        return {ok = false, err = "Room not found"}
    end

    -- 只有房主能开始游戏
    if uid ~= room.owner_uid then
        return {ok = false, err = "Only owner can start game"}
    end

    -- 检查房间状态
    if room.state ~= ROOM_STATE.WAITING then
        return {ok = false, err = "Room is not waiting"}
    end

    -- 检查人数
    if room.player_count < room.config.min_players then
        return {ok = false, err = "Not enough players"}
    end

    -- 检查是否全员准备
    if not check_all_ready(room) then
        return {ok = false, err = "Not all players ready"}
    end

    -- 更新房间状态
    room.state = ROOM_STATE.PLAYING
    for _, player in pairs(room.players) do
        player.state = PLAYER_STATE.PLAYING
    end

    -- 广播游戏开始
    local msg = {
        pid = "s2c_game_started",
        room_id = room_id,
        room_info = get_room_detail(room),
    }
    broadcast_to_room(room_id, msg)

    logger.info("room", "Game started", "room_id:", room_id)

    return {ok = true, room_info = get_room_detail(room)}
end

-- 获取房间信息
function _M.get_room_info(uid)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        uid2room[uid] = nil
        return {ok = false, err = "Room not found"}
    end

    return {ok = true, room_info = get_room_detail(room)}
end

-- 获取房间列表
function _M.get_room_list(game_type, page, page_size)
    page = page or 1
    page_size = page_size or 10

    local list = {}
    for _, room in pairs(rooms) do
        -- 过滤私密房间和游戏中的房间
        if not room.config.is_private and room.state == ROOM_STATE.WAITING then
            -- 过滤游戏类型
            if not game_type or room.config.game_type == game_type then
                table.insert(list, get_room_brief(room))
            end
        end
    end

    -- 按创建时间排序
    table.sort(list, function(a, b) return a.create_time > b.create_time end)

    -- 分页
    local total = #list
    local start_idx = (page - 1) * page_size + 1
    local end_idx = math.min(start_idx + page_size - 1, total)

    local result = {}
    for i = start_idx, end_idx do
        table.insert(result, list[i])
    end

    return {
        ok = true,
        list = result,
        total = total,
        page = page,
        page_size = page_size,
    }
end

-- 快速加入
function _M.quick_join(uid, game_type)
    -- 检查玩家是否已在房间中
    if uid2room[uid] then
        return {ok = false, err = "Already in a room"}
    end

    -- 查找合适的房间
    for room_id, room in pairs(rooms) do
        if room.state == ROOM_STATE.WAITING
            and not room.config.is_private
            and room.player_count < room.config.max_players then
            if not game_type or room.config.game_type == game_type then
                return _M.join_room(uid, room_id)
            end
        end
    end

    -- 没有合适的房间，创建新房间
    local config = {game_type = game_type or "default"}
    return _M.create_room(uid, config)
end

-- 玩家断线
function _M.player_disconnect(uid)
    local room_id = uid2room[uid]
    if not room_id then return end

    local room = rooms[room_id]
    if not room then
        uid2room[uid] = nil
        return
    end

    local player = room.players[uid]
    if not player then return end

    -- 如果在等待状态，直接离开房间
    if room.state == ROOM_STATE.WAITING then
        _M.leave_room(uid)
        return
    end

    -- 游戏中标记为离线
    player.state = PLAYER_STATE.OFFLINE
    player.offline_time = os.time()

    -- 广播玩家离线
    local msg = {
        pid = "s2c_player_offline",
        room_id = room_id,
        uid = uid,
    }
    broadcast_to_room(room_id, msg, uid)

    logger.info("room", "Player offline", "uid:", uid, "room_id:", room_id)
end

-- 玩家重连
function _M.player_reconnect(uid)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        uid2room[uid] = nil
        return {ok = false, err = "Room not found"}
    end

    local player = room.players[uid]
    if not player then
        return {ok = false, err = "Player not found"}
    end

    -- 恢复状态
    if player.state == PLAYER_STATE.OFFLINE then
        player.state = PLAYER_STATE.PLAYING
        player.offline_time = nil
    end

    -- 广播玩家重连
    local msg = {
        pid = "s2c_player_reconnected",
        room_id = room_id,
        uid = uid,
    }
    broadcast_to_room(room_id, msg, uid)

    logger.info("room", "Player reconnected", "uid:", uid, "room_id:", room_id)

    return {ok = true, room_info = get_room_detail(room)}
end

-- 房间内聊天
function _M.room_chat(uid, msg)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        return {ok = false, err = "Room not found"}
    end

    -- 广播聊天消息
    local chat_msg = {
        pid = "s2c_room_chat",
        room_id = room_id,
        uid = uid,
        msg = msg,
        time = os.time(),
    }
    broadcast_to_room(room_id, chat_msg)

    return {ok = true}
end

-- 修改房间设置
function _M.update_room_config(uid, config)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        return {ok = false, err = "Room not found"}
    end

    -- 只有房主能修改
    if uid ~= room.owner_uid then
        return {ok = false, err = "Only owner can update config"}
    end

    -- 只能在等待状态修改
    if room.state ~= ROOM_STATE.WAITING then
        return {ok = false, err = "Cannot update during game"}
    end

    -- 更新配置
    if config then
        for k, v in pairs(config) do
            if DEFAULT_CONFIG[k] ~= nil then
                room.config[k] = v
            end
        end
    end

    -- 广播配置变更
    local msg = {
        pid = "s2c_room_config_updated",
        room_id = room_id,
        config = {
            max_players = room.config.max_players,
            min_players = room.config.min_players,
            game_type = room.config.game_type,
            is_private = room.config.is_private,
            auto_start = room.config.auto_start,
        },
    }
    broadcast_to_room(room_id, msg)

    return {ok = true}
end

-- 换座位
function _M.change_seat(uid, seat_index)
    local room_id = uid2room[uid]
    if not room_id then
        return {ok = false, err = "Not in a room"}
    end

    local room = rooms[room_id]
    if not room then
        return {ok = false, err = "Room not found"}
    end

    -- 只能在等待状态换座位
    if room.state ~= ROOM_STATE.WAITING then
        return {ok = false, err = "Cannot change seat during game"}
    end

    -- 检查座位是否有效
    if seat_index < 1 or seat_index > room.config.max_players then
        return {ok = false, err = "Invalid seat index"}
    end

    -- 检查座位是否被占用
    for _, player in pairs(room.players) do
        if player.seat_index == seat_index and player.uid ~= uid then
            return {ok = false, err = "Seat is occupied"}
        end
    end

    local player = room.players[uid]
    local old_seat = player.seat_index
    player.seat_index = seat_index

    -- 广播座位变更
    local msg = {
        pid = "s2c_seat_changed",
        room_id = room_id,
        uid = uid,
        old_seat = old_seat,
        new_seat = seat_index,
    }
    broadcast_to_room(room_id, msg)

    return {ok = true}
end

-- 获取玩家所在房间ID
function _M.get_player_room(uid)
    return uid2room[uid]
end

-- 结束游戏
function _M.end_game(room_id, result)
    local room = rooms[room_id]
    if not room then return end

    room.state = ROOM_STATE.FINISHED

    -- 广播游戏结束
    local msg = {
        pid = "s2c_game_ended",
        room_id = room_id,
        result = result,
    }
    broadcast_to_room(room_id, msg)

    -- 重置玩家状态
    for _, player in pairs(room.players) do
        player.state = PLAYER_STATE.NOT_READY
    end
    room.state = ROOM_STATE.WAITING

    logger.info("room", "Game ended", "room_id:", room_id)
end

return _M
