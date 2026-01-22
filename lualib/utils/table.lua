local string = require "string"

local _M = {}

-- 检查是否为 table 类型
local function check_table(t, func_name)
    if type(t) ~= "table" then
        error(string.format("%s: expected table, got %s", func_name, type(t)), 3)
    end
end

-- 打印 table 内容（调试用）
function _M.dump(t) 
    if t == nil then
        print("nil")
        return
    end
    
    local print_r_cache = {}
    local function sub_print_table(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. tostring(pos) .. "] => " .. tostring(t) .. " {")
                        sub_print_table(val, indent .. string.rep(" ", string.len(tostring(pos)) + 8))
                        print(indent .. string.rep(" ", string.len(tostring(pos)) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. tostring(pos) .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. tostring(pos) .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end
    if (type(t) == "table") then
        print(tostring(t) .. " {")
        sub_print_table(t, "  ")
        print("}")
    else
        sub_print_table(t, "  ")
    end
    print()
end

-- 获取 table 的所有 key 组成的数组
function _M.klist(t)
    if t == nil then
        return {}
    end
    check_table(t, "klist")
    
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

-- 获取 table 的所有 value 组成的数组
function _M.vlist(t)
    if t == nil then
        return {}
    end
    check_table(t, "vlist")
    
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

-- 获取 table 的长度（包括非数字 key）
function _M.size(t)
    if t == nil then
        return 0
    end
    check_table(t, "size")
    
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- 深拷贝
function _M.clone(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[_M.clone(k)] = _M.clone(v)
    end
    return copy
end

-- 合并两个 table（将 t2 合并到 t1）
function _M.merge(t1, t2)
    if t1 == nil then
        error("merge: t1 cannot be nil", 2)
    end
    check_table(t1, "merge")
    
    if t2 == nil then
        return t1
    end
    check_table(t2, "merge")
    
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

-- 检查 table 是否为空
function _M.is_empty(t)
    if t == nil then
        return true
    end
    if type(t) ~= "table" then
        return true
    end
    return next(t) == nil
end

-- 检查 key 是否存在
function _M.has_key(t, key)
    if t == nil or type(t) ~= "table" then
        return false
    end
    return t[key] ~= nil
end

-- 检查 value 是否存在
function _M.has_value(t, value)
    if t == nil or type(t) ~= "table" then
        return false
    end
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

-- 根据 value 查找 key
function _M.find_key(t, value)
    if t == nil then
        return nil
    end
    check_table(t, "find_key")
    
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
    return nil
end

-- 过滤 table（返回满足条件的元素）
function _M.filter(t, func)
    if t == nil then
        return {}
    end
    check_table(t, "filter")
    if type(func) ~= "function" then
        error("filter: expected function for filter condition", 2)
    end
    
    local result = {}
    for k, v in pairs(t) do
        if func(k, v) then
            result[k] = v
        end
    end
    return result
end

-- 映射 table（对每个元素应用函数）
function _M.map(t, func)
    if t == nil then
        return {}
    end
    check_table(t, "map")
    if type(func) ~= "function" then
        error("map: expected function for map operation", 2)
    end
    
    local result = {}
    for k, v in pairs(t) do
        result[k] = func(k, v)
    end
    return result
end

-- 数组反转
function _M.reverse(t)
    if t == nil then
        return {}
    end
    check_table(t, "reverse")
    
    local result = {}
    local len = #t
    for i = 1, len do
        result[i] = t[len - i + 1]
    end
    return result
end

-- 数组切片
function _M.slice(t, start_idx, end_idx)
    if t == nil then
        return {}
    end
    check_table(t, "slice")
    
    local len = #t
    start_idx = start_idx or 1
    end_idx = end_idx or len
    
    if type(start_idx) ~= "number" or type(end_idx) ~= "number" then
        error("slice: start_idx and end_idx must be numbers", 2)
    end
    
    -- 处理负数索引
    if start_idx < 0 then
        start_idx = len + start_idx + 1
    end
    if end_idx < 0 then
        end_idx = len + end_idx + 1
    end
    
    -- 边界检查
    start_idx = math.max(1, start_idx)
    end_idx = math.min(len, end_idx)
    
    local result = {}
    for i = start_idx, end_idx do
        table.insert(result, t[i])
    end
    return result
end

-- 随机打乱数组
function _M.shuffle(t)
    if t == nil then
        return {}
    end
    check_table(t, "shuffle")
    
    local result = _M.clone(t)
    local len = #result
    for i = len, 2, -1 do
        local j = math.random(1, i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

-- 从数组中随机取一个元素
function _M.random_pick(t)
    if t == nil then
        return nil
    end
    check_table(t, "random_pick")
    
    local len = #t
    if len == 0 then
        return nil
    end
    return t[math.random(1, len)]
end

return _M
