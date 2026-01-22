-- 测试文件：用于验证 GitHub Actions 代码审查是否生效
-- 这个文件故意包含一些问题

local skynet = require "skynet"

local _M = {}

-- TODO: 这是一个待办事项，应该被检测到

-- FIXME: 这是一个需要修复的问题

-- 问题1: 使用 print 而不是 logger（应该被检测到）
function _M.test_print()
    print("This should use logger instead")
    print("Another debug print")
end

-- 问题2: 硬编码的密码（应该被安全检查检测到）
local password = "my_secret_password_123"
local api_key = "sk-1234567890abcdef"

-- 问题3: 超长行（超过120字符，应该被检测到）
local very_long_variable_name_that_exceeds_the_maximum_line_length_limit = "this is a very long string that makes this line exceed 120 characters for testing purposes"

-- 问题4: 未使用的变量
local unused_variable = "I am never used"

-- 问题5: 潜在的 SQL 注入风险
function _M.unsafe_query(user_input)
    local sql = string.format("SELECT * FROM users WHERE name = '%s'", user_input)
    return sql
end

-- 问题6: 语法正确但风格不好的代码
function _M.bad_style()
    local a=1
    local b=2
    if a==b then
        return true
    else
        return false
    end
end

-- 正常的函数
function _M.normal_function(param)
    if param then
        return param * 2
    end
    return 0
end

return _M
