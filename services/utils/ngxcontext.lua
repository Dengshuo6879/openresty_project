--[[
ngx相关上下文信息的获取工具类
]]

local _M = {}

--[[
获得远程客户端真实IP地址
]]
function _M.getRemoteIP()

    local headers=ngx.req.get_headers()
    local clientIP = headers["x-forwarded-for"]
    if clientIP == nil or string.len(clientIP) == 0 or clientIP == "unknown" then
           clientIP = headers["Proxy-Client-IP"]
    end
    if clientIP == nil or string.len(clientIP) == 0 or clientIP == "unknown" then
           clientIP = headers["WL-Proxy-Client-IP"]
    end
    if clientIP == nil or string.len(clientIP) == 0 or clientIP == "unknown" then
           clientIP = ngx.var.remote_addr    
    end
    -- 对于通过多个代理的情况，第一个IP为客户端真实IP,多个IP按照','分割
    if clientIP ~= nil and string.len(clientIP) >15  then
           local pos  = string.find(clientIP, ",", 1)
           clientIP = string.sub(clientIP,1,pos-1)
    end

    return clientIP
end

return _M