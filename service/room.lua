local skynet = require "skynet"
require "skynet.manager"
local logger = require "logger"
local cjson = require "cjson"

local room_mng = require "room.mng"

local CMD = {}

-- 创建房间
function CMD.create_room(uid, room_config)
    return room_mng.create_room(uid, room_config)
end

-- 加入房间
function CMD.join_room(uid, room_id, password)
    return room_mng.join_room(uid, room_id, password)
end

-- 离开房间
function CMD.leave_room(uid)
    return room_mng.leave_room(uid)
end

-- 解散房间
function CMD.dismiss_room(uid)
    return room_mng.dismiss_room(uid)
end

-- 踢出玩家
function CMD.kick_player(uid, target_uid)
    return room_mng.kick_player(uid, target_uid)
end

-- 转让房主
function CMD.transfer_owner(uid, target_uid)
    return room_mng.transfer_owner(uid, target_uid)
end

-- 准备/取消准备
function CMD.set_ready(uid, is_ready)
    return room_mng.set_ready(uid, is_ready)
end

-- 开始游戏
function CMD.start_game(uid)
    return room_mng.start_game(uid)
end

-- 获取房间信息
function CMD.get_room_info(uid)
    return room_mng.get_room_info(uid)
end

-- 获取房间列表
function CMD.get_room_list(game_type, page, page_size)
    return room_mng.get_room_list(game_type, page, page_size)
end

-- 快速加入
function CMD.quick_join(uid, game_type)
    return room_mng.quick_join(uid, game_type)
end

-- 玩家断线
function CMD.player_disconnect(uid)
    return room_mng.player_disconnect(uid)
end

-- 玩家重连
function CMD.player_reconnect(uid)
    return room_mng.player_reconnect(uid)
end

-- 房间内聊天
function CMD.room_chat(uid, msg)
    return room_mng.room_chat(uid, msg)
end

-- 修改房间设置
function CMD.update_room_config(uid, config)
    return room_mng.update_room_config(uid, config)
end

-- 换座位
function CMD.change_seat(uid, seat_index)
    return room_mng.change_seat(uid, seat_index)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if not f then
            logger.error(SERVICE_NAME, "Unknown command:", cmd)
            skynet.ret(skynet.pack({ok = false, err = "Unknown command"}))
            return
        end
        skynet.ret(skynet.pack(f(...)))
    end)

    room_mng.init()
    skynet.register(".room")
    logger.info(SERVICE_NAME, "room service started")
end)
