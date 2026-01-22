-- Luacheck configuration for Skynet-based game server

-- 全局设置
std = "lua53"
max_line_length = 120

-- 忽略的目录
exclude_files = {
    "skynet/*",
    "luaclib/*",
}

-- 全局变量白名单（Skynet 相关）
globals = {
    "skynet",
    "SERVICE_NAME",
    "SERVICE_ADDRESS",
}

-- 只读全局变量
read_globals = {
    "skynet",
    "SERVICE_NAME",
    "SERVICE_ADDRESS",
    -- Lua 标准库
    "table",
    "string",
    "math",
    "os",
    "io",
    "debug",
    "coroutine",
    "package",
    "pairs",
    "ipairs",
    "next",
    "type",
    "tostring",
    "tonumber",
    "print",
    "error",
    "assert",
    "pcall",
    "xpcall",
    "select",
    "setmetatable",
    "getmetatable",
    "rawget",
    "rawset",
    "require",
    "loadfile",
    "dofile",
    "collectgarbage",
    "unpack",
}

-- 忽略的警告
ignore = {
    "211",  -- 未使用的局部变量（有时是故意的）
    "212",  -- 未使用的参数（回调函数常见）
    "213",  -- 未使用的循环变量
    "311",  -- 未使用的赋值（有时用于占位）
    "411",  -- 变量重定义
    "421",  -- 变量遮蔽
    "431",  -- 变量遮蔽上层作用域
    "542",  -- 空的 if 分支
}

-- 特定文件的配置
files["test/*"] = {
    ignore = {"111", "112", "113"},  -- 测试文件允许更宽松
}

files["service/*"] = {
    globals = {"CMD", "SOCKET", "RPC"},
}

files["module/*"] = {
    globals = {"RPC"},
}
