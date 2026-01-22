# 协议文档

本文档整理了桌游模拟器所有的客户端-服务端通信协议。

## 协议格式

所有协议使用 JSON 格式，通过 WebSocket 传输。

### 请求格式 (Client -> Server)
```json
{
    "pid": "c2s_xxx",
    // ... 其他参数
}
```

### 响应格式 (Server -> Client)
```json
{
    "pid": "s2c_xxx",
    "ok": true/false,
    "err": "错误信息（可选）",
    // ... 其他数据
}
```

---

## 一、基础协议

### 1.1 登录协议

#### c2s_login - 登录请求
```json
{
    "pid": "c2s_login",
    "acc": "账号",
    "token": "令牌",
    "sign": "MD5签名(token + acc)"
}
```

#### s2c_login - 登录响应
```json
{
    "pid": "s2c_login",
    "ok": true,
    "msg": "Login success",
    "uid": 1
}
```

---

### 1.2 心跳协议

#### c2s_heartbeat - 心跳请求
```json
{
    "pid": "c2s_heartbeat"
}
```

> 注：心跳协议无响应，服务端仅更新心跳时间

---

### 1.3 回显协议

#### c2s_echo - 回显请求
```json
{
    "pid": "c2s_echo",
    "msg": "消息内容"
}
```

#### s2c_echo - 回显响应
```json
{
    "pid": "s2c_echo",
    "msg": "消息内容",
    "uid": 1
}
```

---

### 1.4 用户信息协议

#### c2s_get_userinfo - 获取用户信息
```json
{
    "pid": "c2s_get_userinfo"
}
```

#### s2c_get_userinfo - 用户信息响应
```json
{
    "pid": "s2c_get_userinfo",
    "userinfo": {
        "uid": 1,
        "username": "用户名",
        "lv": 1,
        "exp": 0
    }
}
```

#### c2s_get_username - 获取用户名
```json
{
    "pid": "c2s_get_username"
}
```

#### s2c_get_username - 用户名响应
```json
{
    "pid": "s2c_get_username",
    "username": "用户名"
}
```

#### c2s_set_username - 设置用户名
```json
{
    "pid": "c2s_set_username",
    "username": "新用户名"
}
```

#### s2c_set_username - 设置用户名响应
```json
{
    "pid": "s2c_set_username",
    "msg": "success set username: xxx"
}
```

---

## 二、房间协议

### 2.1 房间管理

#### c2s_create_room - 创建房间
```json
{
    "pid": "c2s_create_room",
    "config": {
        "max_players": 4,       // 最大玩家数，默认4
        "min_players": 2,       // 最小开始人数，默认2
        "game_type": "default", // 游戏类型
        "is_private": false,    // 是否私密房间
        "password": null,       // 房间密码
        "auto_start": false     // 全员准备后自动开始
    }
}
```

#### s2c_create_room - 创建房间响应
```json
{
    "pid": "s2c_create_room",
    "ok": true,
    "room_id": "123456789",
    "room_info": { /* 房间详情 */ }
}
```

#### c2s_join_room - 加入房间
```json
{
    "pid": "c2s_join_room",
    "room_id": "123456789",
    "password": "密码（可选）"
}
```

#### s2c_join_room - 加入房间响应
```json
{
    "pid": "s2c_join_room",
    "ok": true,
    "room_info": { /* 房间详情 */ }
}
```

#### c2s_leave_room - 离开房间
```json
{
    "pid": "c2s_leave_room"
}
```

#### s2c_leave_room - 离开房间响应
```json
{
    "pid": "s2c_leave_room",
    "ok": true
}
```

#### c2s_dismiss_room - 解散房间（仅房主）
```json
{
    "pid": "c2s_dismiss_room"
}
```

#### s2c_dismiss_room - 解散房间响应
```json
{
    "pid": "s2c_dismiss_room",
    "ok": true
}
```

---

### 2.2 房间操作

#### c2s_kick_player - 踢出玩家（仅房主）
```json
{
    "pid": "c2s_kick_player",
    "target_uid": 2
}
```

#### s2c_kick_player - 踢出玩家响应
```json
{
    "pid": "s2c_kick_player",
    "ok": true
}
```

#### c2s_transfer_owner - 转让房主
```json
{
    "pid": "c2s_transfer_owner",
    "target_uid": 2
}
```

#### s2c_transfer_owner - 转让房主响应
```json
{
    "pid": "s2c_transfer_owner",
    "ok": true
}
```

#### c2s_update_room_config - 修改房间设置（仅房主）
```json
{
    "pid": "c2s_update_room_config",
    "config": {
        "max_players": 6,
        "auto_start": true
    }
}
```

#### s2c_update_room_config - 修改房间设置响应
```json
{
    "pid": "s2c_update_room_config",
    "ok": true
}
```

#### c2s_change_seat - 换座位
```json
{
    "pid": "c2s_change_seat",
    "seat_index": 3
}
```

#### s2c_change_seat - 换座位响应
```json
{
    "pid": "s2c_change_seat",
    "ok": true
}
```

---

### 2.3 游戏控制

#### c2s_set_ready - 准备/取消准备
```json
{
    "pid": "c2s_set_ready",
    "is_ready": true
}
```

#### s2c_set_ready - 准备状态响应
```json
{
    "pid": "s2c_set_ready",
    "ok": true
}
```

#### c2s_start_game - 开始游戏（仅房主）
```json
{
    "pid": "c2s_start_game"
}
```

#### s2c_start_game - 开始游戏响应
```json
{
    "pid": "s2c_start_game",
    "ok": true,
    "room_info": { /* 房间详情 */ }
}
```

---

### 2.4 房间查询

#### c2s_get_room_info - 获取当前房间信息
```json
{
    "pid": "c2s_get_room_info"
}
```

#### s2c_get_room_info - 房间信息响应
```json
{
    "pid": "s2c_get_room_info",
    "ok": true,
    "room_info": {
        "room_id": "123456789",
        "owner_uid": 1,
        "config": {
            "max_players": 4,
            "min_players": 2,
            "game_type": "default",
            "is_private": false,
            "auto_start": false
        },
        "state": 1,
        "players": [
            {
                "uid": 1,
                "seat_index": 1,
                "state": 0,
                "join_time": 1234567890,
                "is_owner": true
            }
        ],
        "player_count": 1,
        "create_time": 1234567890
    }
}
```

#### c2s_get_room_list - 获取房间列表
```json
{
    "pid": "c2s_get_room_list",
    "game_type": "default",  // 可选，筛选游戏类型
    "page": 1,
    "page_size": 10
}
```

#### s2c_get_room_list - 房间列表响应
```json
{
    "pid": "s2c_get_room_list",
    "ok": true,
    "list": [
        {
            "room_id": "123456789",
            "owner_uid": 1,
            "game_type": "default",
            "player_count": 2,
            "max_players": 4,
            "state": 1,
            "is_private": false,
            "create_time": 1234567890
        }
    ],
    "total": 1,
    "page": 1,
    "page_size": 10
}
```

#### c2s_quick_join - 快速加入
```json
{
    "pid": "c2s_quick_join",
    "game_type": "default"  // 可选
}
```

#### s2c_quick_join - 快速加入响应
```json
{
    "pid": "s2c_quick_join",
    "ok": true,
    "room_id": "123456789",
    "room_info": { /* 房间详情 */ }
}
```

---

### 2.5 房间聊天

#### c2s_room_chat - 发送聊天消息
```json
{
    "pid": "c2s_room_chat",
    "msg": "聊天内容"
}
```

#### s2c_room_chat - 聊天消息响应/广播
```json
{
    "pid": "s2c_room_chat",
    "ok": true,
    "room_id": "123456789",
    "uid": 1,
    "msg": "聊天内容",
    "time": 1234567890
}
```

---

## 三、服务端推送协议

以下协议由服务端主动推送给房间内的玩家。

### 3.1 玩家状态变化

#### s2c_player_joined - 玩家加入房间
```json
{
    "pid": "s2c_player_joined",
    "room_id": "123456789",
    "player": {
        "uid": 2,
        "seat_index": 2,
        "state": 0
    },
    "player_count": 2
}
```

#### s2c_player_left - 玩家离开房间
```json
{
    "pid": "s2c_player_left",
    "room_id": "123456789",
    "uid": 2,
    "player_count": 1
}
```

#### s2c_player_kicked - 玩家被踢出
```json
{
    "pid": "s2c_player_kicked",
    "room_id": "123456789",
    "uid": 2,
    "player_count": 1
}
```

#### s2c_kicked - 你被踢出房间
```json
{
    "pid": "s2c_kicked",
    "room_id": "123456789"
}
```

#### s2c_player_ready - 玩家准备状态变化
```json
{
    "pid": "s2c_player_ready",
    "room_id": "123456789",
    "uid": 2,
    "is_ready": true
}
```

#### s2c_player_offline - 玩家断线
```json
{
    "pid": "s2c_player_offline",
    "room_id": "123456789",
    "uid": 2
}
```

#### s2c_player_reconnected - 玩家重连
```json
{
    "pid": "s2c_player_reconnected",
    "room_id": "123456789",
    "uid": 2
}
```

---

### 3.2 房间状态变化

#### s2c_owner_changed - 房主变更
```json
{
    "pid": "s2c_owner_changed",
    "room_id": "123456789",
    "new_owner_uid": 2
}
```

#### s2c_room_config_updated - 房间配置更新
```json
{
    "pid": "s2c_room_config_updated",
    "room_id": "123456789",
    "config": {
        "max_players": 6,
        "min_players": 2,
        "game_type": "default",
        "is_private": false,
        "auto_start": true
    }
}
```

#### s2c_seat_changed - 座位变更
```json
{
    "pid": "s2c_seat_changed",
    "room_id": "123456789",
    "uid": 2,
    "old_seat": 2,
    "new_seat": 3
}
```

#### s2c_room_dismissed - 房间解散
```json
{
    "pid": "s2c_room_dismissed",
    "room_id": "123456789",
    "reason": "owner_dismissed"  // 可能值: owner_dismissed, timeout, empty
}
```

---

### 3.3 游戏状态变化

#### s2c_game_started - 游戏开始
```json
{
    "pid": "s2c_game_started",
    "room_id": "123456789",
    "room_info": { /* 房间详情 */ }
}
```

#### s2c_game_ended - 游戏结束
```json
{
    "pid": "s2c_game_ended",
    "room_id": "123456789",
    "result": { /* 游戏结果 */ }
}
```

---

## 四、常量定义

### 房间状态 (ROOM_STATE)
| 值 | 名称 | 说明 |
|----|------|------|
| 1 | WAITING | 等待中 |
| 2 | PLAYING | 游戏中 |
| 3 | FINISHED | 已结束 |

### 玩家状态 (PLAYER_STATE)
| 值 | 名称 | 说明 |
|----|------|------|
| 0 | NOT_READY | 未准备 |
| 1 | READY | 已准备 |
| 2 | PLAYING | 游戏中 |
| 3 | OFFLINE | 离线 |

---

## 五、错误码

所有协议响应中，当 `ok` 为 `false` 时，`err` 字段包含错误信息：

| 错误信息 | 说明 |
|----------|------|
| Already in a room | 已在房间中 |
| Room not found | 房间不存在 |
| Room is not waiting | 房间不在等待状态 |
| Room is full | 房间已满 |
| Wrong password | 密码错误 |
| Not in a room | 不在房间中 |
| Cannot leave during game | 游戏中不能离开 |
| Only owner can dismiss room | 只有房主能解散房间 |
| Only owner can kick player | 只有房主能踢人 |
| Cannot kick yourself | 不能踢自己 |
| Target not in room | 目标不在房间中 |
| Cannot kick during game | 游戏中不能踢人 |
| Only owner can transfer | 只有房主能转让 |
| Cannot transfer to yourself | 不能转让给自己 |
| Owner does not need to ready | 房主不需要准备 |
| Only owner can start game | 只有房主能开始游戏 |
| Not enough players | 玩家人数不足 |
| Not all players ready | 不是所有玩家都准备好了 |
| Only owner can update config | 只有房主能修改配置 |
| Cannot update during game | 游戏中不能修改配置 |
| Cannot change seat during game | 游戏中不能换座位 |
| Invalid seat index | 无效的座位号 |
| Seat is occupied | 座位已被占用 |
| Room service not available | 房间服务不可用 |
