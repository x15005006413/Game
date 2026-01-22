local skynet = require "skynet"
local logger = require "logger"

local _M = {}
local RPC = {}

-- 获取房间服务地址
local function get_room_service()
    return skynet.localname(".room")
end

-- 创建房间
function RPC.c2s_create_room(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local config = req.config or {}
    local result = skynet.call(room_service, "lua", "create_room", uid, config)

    local res = {
        ok = result.ok,
        err = result.err,
        room_id = result.room_id,
        room_info = result.room_info,
    }
    return res
end

-- 加入房间
function RPC.c2s_join_room(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "join_room", uid, req.room_id, req.password)

    local res = {
        ok = result.ok,
        err = result.err,
        room_info = result.room_info,
    }
    return res
end

-- 离开房间
function RPC.c2s_leave_room(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "leave_room", uid)

    local res = {
        ok = result.ok,
        err = result.err,
    }
    return res
end

-- 解散房间
function RPC.c2s_dismiss_room(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "dismiss_room", uid)

    local res = {
        ok = result.ok,
        err = result.err,
    }
    return res
end

-- 踢出玩家
function RPC.c2s_kick_player(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "kick_player", uid, req.target_uid)

    local res = {
        ok = result.ok,
        err = result.err,
    }
    return res
end

-- 转让房主
function RPC.c2s_transfer_owner(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "transfer_owner", uid, req.target_uid)

    local res = {
        ok = result.ok,
        err = result.err,
    }
    return res
end

-- 准备/取消准备
function RPC.c2s_set_ready(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "set_ready", uid, req.is_ready)

    local res = {
        ok = result.ok,
        err = result.err,
    }
    return res
end

-- 开始游戏
function RPC.c2s_start_game(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "start_game", uid)

    local res = {
        ok = result.ok,
        err = result.err,
        room_info = result.room_info,
    }
    return res
end

-- 获取房间信息
function RPC.c2s_get_room_info(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "get_room_info", uid)

    local res = {
        ok = result.ok,
        err = result.err,
        room_info = result.room_info,
    }
    return res
end

-- 获取房间列表
function RPC.c2s_get_room_list(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "get_room_list", req.game_type, req.page, req.page_size)

    local res = {
        ok = result.ok,
        err = result.err,
        list = result.list,
        total = result.total,
        page = result.page,
        page_size = result.page_size,
    }
    return res
end

-- 快速加入
function RPC.c2s_quick_join(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "quick_join", uid, req.game_type)

    local res = {
        ok = result.ok,
        err = result.err,
        room_id = result.room_id,
        room_info = result.room_info,
    }
    return res
end

-- 房间内聊天
function RPC.c2s_room_chat(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "room_chat", uid, req.msg)

    local res = {
        ok = result.ok,
        err = result.err,
    }
    return res
end

-- 修改房间设置
function RPC.c2s_update_room_config(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "update_room_config", uid, req.config)

    local res = {
        ok = result.ok,
        err = result.err,
    }
    return res
end

-- 换座位
function RPC.c2s_change_seat(req, fd, uid)
    local room_service = get_room_service()
    if not room_service then
        return {ok = false, err = "Room service not available"}
    end

    local result = skynet.call(room_service, "lua", "change_seat", uid, req.seat_index)

    local res = {
        ok = result.ok,
        err = result.err,
    }
    return res
end

-- 获取所有 RPC 函数
function _M.get_rpc()
    return RPC
end

return _M
