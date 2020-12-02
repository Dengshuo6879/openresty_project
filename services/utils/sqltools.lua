--[[
sql字符处理工具模块
]]

local _M = {}

function _M.sqlValue(value)
    if value == "NULL" or 
       type(value) == "number" then
        return value
    end
    return string.format([["%s"]], value)
end

--[[
    防止SQL注入
]]
function _M.sqlEscape(val)
    if val and 
        val ~= ngx.null then
        val = ngx.quote_sql_str(val)
        val = string.gsub(val, [[%$]], "#DOLLAR#")
        return val
    else
        return "NULL"
    end
end

--[[
    防止SQL注入反转义
]]
function _M.sqlAntisense(val)
    if val and 
        val ~= ngx.null then
        val = string.gsub(val, [[#DOLLAR#]], "$")
        return val
    else
        return nil
    end
end

return _M
