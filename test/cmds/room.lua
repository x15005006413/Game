local cjson = require "cjson"
local websocket = require "http.websocket"
local logger = require "logger"

local _M = {}
local CMD = {}
local RPC = {}

------------  RPC -----------------

function RPC.s2c_create_room(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Room created:", res.room_id)
        logger.debug(SERVICE_NAME, "Room info:", cjson.encode(res.room_info))
    else
        logger.debug(SERVICE_NAME, "Create room failed:", res.err)
    end
end

function RPC.s2c_join_room(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Joined room successfully")
        logger.debug(SERVICE_NAME, "Room info:", cjson.encode(res.room_info))
    else
        logger.debug(SERVICE_NAME, "Join room failed:", res.err)
    end
end

function RPC.s2c_leave_room(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Left room successfully")
    else
        logger.debug(SERVICE_NAME, "Leave room failed:", res.err)
    end
end

function RPC.s2c_dismiss_room(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Room dismissed successfully")
    else
        logger.debug(SERVICE_NAME, "Dismiss room failed:", res.err)
    end
end

function RPC.s2c_kick_player(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Player kicked successfully")
    else
        logger.debug(SERVICE_NAME, "Kick player failed:", res.err)
    end
end

function RPC.s2c_transfer_owner(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Owner transferred successfully")
    else
        logger.debug(SERVICE_NAME, "Transfer owner failed:", res.err)
    end
end

function RPC.s2c_set_ready(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Ready state changed successfully")
    else
        logger.debug(SERVICE_NAME, "Set ready failed:", res.err)
    end
end

function RPC.s2c_start_game(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Game started!")
        logger.debug(SERVICE_NAME, "Room info:", cjson.encode(res.room_info))
    else
        logger.debug(SERVICE_NAME, "Start game failed:", res.err)
    end
end

function RPC.s2c_get_room_info(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Room info:", cjson.encode(res.room_info))
    else
        logger.debug(SERVICE_NAME, "Get room info failed:", res.err)
    end
end

function RPC.s2c_get_room_list(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Room list (total:", res.total, "):")
        for i, room in ipairs(res.list or {}) do
            logger.debug(SERVICE_NAME, string.format("  [%d] id:%s type:%s players:%d/%d",
                i, room.room_id, room.game_type, room.player_count, room.max_players))
        end
    else
        logger.debug(SERVICE_NAME, "Get room list failed:", res.err)
    end
end

function RPC.s2c_quick_join(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Quick join successful, room_id:", res.room_id)
        logger.debug(SERVICE_NAME, "Room info:", cjson.encode(res.room_info))
    else
        logger.debug(SERVICE_NAME, "Quick join failed:", res.err)
    end
end

function RPC.s2c_room_chat(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Chat sent successfully")
    else
        logger.debug(SERVICE_NAME, "Chat failed:", res.err)
    end
end

function RPC.s2c_update_room_config(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Room config updated successfully")
    else
        logger.debug(SERVICE_NAME, "Update config failed:", res.err)
    end
end

function RPC.s2c_change_seat(ws_id, res)
    if res.ok then
        logger.debug(SERVICE_NAME, "Seat changed successfully")
    else
        logger.debug(SERVICE_NAME, "Change seat failed:", res.err)
    end
end

-- 服务器推送消息处理
function RPC.s2c_player_joined(ws_id, res)
    logger.debug(SERVICE_NAME, "Player joined:", res.player.uid, "seat:", res.player.seat_index)
end

function RPC.s2c_player_left(ws_id, res)
    logger.debug(SERVICE_NAME, "Player left:", res.uid)
end

function RPC.s2c_player_kicked(ws_id, res)
    logger.debug(SERVICE_NAME, "Player kicked:", res.uid)
end

function RPC.s2c_kicked(ws_id, res)
    logger.debug(SERVICE_NAME, "You have been kicked from room:", res.room_id)
end

function RPC.s2c_owner_changed(ws_id, res)
    logger.debug(SERVICE_NAME, "New room owner:", res.new_owner_uid)
end

function RPC.s2c_player_ready(ws_id, res)
    logger.debug(SERVICE_NAME, "Player", res.uid, "ready:", res.is_ready)
end

function RPC.s2c_game_started(ws_id, res)
    logger.debug(SERVICE_NAME, "Game started in room:", res.room_id)
end

function RPC.s2c_game_ended(ws_id, res)
    logger.debug(SERVICE_NAME, "Game ended in room:", res.room_id)
end

function RPC.s2c_room_dismissed(ws_id, res)
    logger.debug(SERVICE_NAME, "Room dismissed:", res.room_id, "reason:", res.reason)
end

function RPC.s2c_player_offline(ws_id, res)
    logger.debug(SERVICE_NAME, "Player offline:", res.uid)
end

function RPC.s2c_player_reconnected(ws_id, res)
    logger.debug(SERVICE_NAME, "Player reconnected:", res.uid)
end

function RPC.s2c_room_config_updated(ws_id, res)
    logger.debug(SERVICE_NAME, "Room config updated:", cjson.encode(res.config))
end

function RPC.s2c_seat_changed(ws_id, res)
    logger.debug(SERVICE_NAME, "Player", res.uid, "changed seat from", res.old_seat, "to", res.new_seat)
end

-- 处理网络消息
function _M.handle_res(ws_id, res)
    local f = RPC[res.pid]
    if f then
        f(ws_id, res)
    end
end

------------  CMD -----------------

-- 创建房间: room create [game_type] [max_players]
function CMD.create(ws_id, game_type, max_players)
    local config = {}
    if game_type then
        config.game_type = game_type
    end
    if max_players then
        config.max_players = tonumber(max_players)
    end

    local req = {
        pid = "c2s_create_room",
        config = config,
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 加入房间: room join <room_id> [password]
function CMD.join(ws_id, room_id, password)
    if not room_id then
        logger.debug(SERVICE_NAME, "Usage: room join <room_id> [password]")
        return
    end

    local req = {
        pid = "c2s_join_room",
        room_id = room_id,
        password = password,
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 离开房间: room leave
function CMD.leave(ws_id)
    local req = {
        pid = "c2s_leave_room",
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 解散房间: room dismiss
function CMD.dismiss(ws_id)
    local req = {
        pid = "c2s_dismiss_room",
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 踢出玩家: room kick <target_uid>
function CMD.kick(ws_id, target_uid)
    if not target_uid then
        logger.debug(SERVICE_NAME, "Usage: room kick <target_uid>")
        return
    end

    local req = {
        pid = "c2s_kick_player",
        target_uid = tonumber(target_uid),
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 转让房主: room transfer <target_uid>
function CMD.transfer(ws_id, target_uid)
    if not target_uid then
        logger.debug(SERVICE_NAME, "Usage: room transfer <target_uid>")
        return
    end

    local req = {
        pid = "c2s_transfer_owner",
        target_uid = tonumber(target_uid),
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 准备: room ready
function CMD.ready(ws_id)
    local req = {
        pid = "c2s_set_ready",
        is_ready = true,
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 取消准备: room unready
function CMD.unready(ws_id)
    local req = {
        pid = "c2s_set_ready",
        is_ready = false,
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 开始游戏: room start
function CMD.start(ws_id)
    local req = {
        pid = "c2s_start_game",
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 获取房间信息: room info
function CMD.info(ws_id)
    local req = {
        pid = "c2s_get_room_info",
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 获取房间列表: room list [game_type] [page]
function CMD.list(ws_id, game_type, page)
    local req = {
        pid = "c2s_get_room_list",
        game_type = game_type,
        page = tonumber(page) or 1,
        page_size = 10,
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 快速加入: room quick [game_type]
function CMD.quick(ws_id, game_type)
    local req = {
        pid = "c2s_quick_join",
        game_type = game_type,
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 房间聊天: room chat <message>
function CMD.chat(ws_id, ...)
    local args = {...}
    local msg = table.concat(args, " ")
    if msg == "" then
        logger.debug(SERVICE_NAME, "Usage: room chat <message>")
        return
    end

    local req = {
        pid = "c2s_room_chat",
        msg = msg,
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 换座位: room seat <seat_index>
function CMD.seat(ws_id, seat_index)
    if not seat_index then
        logger.debug(SERVICE_NAME, "Usage: room seat <seat_index>")
        return
    end

    local req = {
        pid = "c2s_change_seat",
        seat_index = tonumber(seat_index),
    }
    websocket.write(ws_id, cjson.encode(req))
end

-- 帮助信息
function CMD.help(ws_id)
    logger.debug(SERVICE_NAME, "Room commands:")
    logger.debug(SERVICE_NAME, "  room create [game_type] [max_players] - Create a room")
    logger.debug(SERVICE_NAME, "  room join <room_id> [password]        - Join a room")
    logger.debug(SERVICE_NAME, "  room leave                            - Leave current room")
    logger.debug(SERVICE_NAME, "  room dismiss                          - Dismiss room (owner only)")
    logger.debug(SERVICE_NAME, "  room kick <target_uid>                - Kick player (owner only)")
    logger.debug(SERVICE_NAME, "  room transfer <target_uid>            - Transfer ownership")
    logger.debug(SERVICE_NAME, "  room ready                            - Set ready")
    logger.debug(SERVICE_NAME, "  room unready                          - Cancel ready")
    logger.debug(SERVICE_NAME, "  room start                            - Start game (owner only)")
    logger.debug(SERVICE_NAME, "  room info                             - Get room info")
    logger.debug(SERVICE_NAME, "  room list [game_type] [page]          - List rooms")
    logger.debug(SERVICE_NAME, "  room quick [game_type]                - Quick join")
    logger.debug(SERVICE_NAME, "  room chat <message>                   - Send chat message")
    logger.debug(SERVICE_NAME, "  room seat <seat_index>                - Change seat")
end

-- 执行指令
function _M.run_command(ws_id, cmd, ...)
    local f = CMD[cmd]
    if not f then
        logger.debug(SERVICE_NAME, "Unknown room command: [" .. (cmd or "") .. "], use 'room help' for help")
        return
    end
    f(ws_id, ...)
end

return _M
