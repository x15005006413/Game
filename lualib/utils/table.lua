local string = require "string"

local _M = {}

function _M.dump(t) 
    local print_r_cache = {}
    local function sub_print_table(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. tostring(t) .. " {")
                        sub_print_table(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
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
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

-- 获取 table 的所有 value 组成的数组
function _M.vlist(t)
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

-- 获取 table 的长度（包括非数字 key）
function _M.size(t)
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

-- 合并两个 table
function _M.merge(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

return _M
