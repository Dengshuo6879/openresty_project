--[[
子系统间服务调用的工具模块
]]

local cjson = require "cjson.safe"
--http工具类
local http = require "resty.http"

--错误码定义
local errorcode = require "errorcode"
--错误信息定义
local errormessage = require "errormessage"

local _M = {}

--[[
在指定的地址集合中，随机选择一个地址

输入参数
    addressList Array[String] 地址列表

return
    index, address

    index Integer 随机选择到的地址下标
    address String 随机选择到的地址
]]
function _M:randomAddress(addressList)

    --ngx.log(ngx.DEBUG, ngx.now())

    math.randomseed(ngx.now())
    local random_index = math.random(1, #addressList)

    --ngx.log(ngx.DEBUG, ngx.now())

    return random_index, addressList[random_index]
end

--[[
调用系统内部的HTTP L1接口服务
采用随机负载均衡方式进行服务调用

输入参数
    subsysaddrList Array[String] 子系统地址列表
    req_url String 服务URL后缀
    body Object 请求报文体，与JSON报文对应的对象

return
    errorCode, errorMessage, result
]]
function _M:callSvc(subsysaddrList,
                    req_url,
                    body)
    
    local httpc  = http:new()

    local _, url_prefix = self:randomAddress(subsysaddrList)
    local req_url_fullpath = (url_prefix or "") .. req_url

    local str_body = cjson.encode(body)

    local res, err = 
    httpc:request_uri(req_url_fullpath, {
        method = "POST",
        body = str_body,
        headers = {
          ["Content-Type"] = "application/json",
        },
        keepalive_timeout = 60000,
        keepalive_pool = 10
    })

    if not res then
        ngx.log(ngx.ERR, "failed to request: ", err)
        return errorcode.INNER_ERR, errormessage.MSG_CALL_SVC .. req_url_fullpath
    end

    local str_resp_body = res.body
    local resp_body = cjson.decode(str_resp_body)
    local result = {}

    --对于应答报文进行容错处理
    if (type(resp_body) ~= "table") then
        result["unkown"] = resp_body
        ngx.log(ngx.ERR, "failed to request: ", err)
        return errorcode.INNER_ERR, errormessage.MSG_CALL_SVC .. req_url_fullpath
    end

    for k, v in pairs(resp_body) do
        if k ~= "errorCode" and k ~= "errorMessage" then
            result[k] = v
        end
    end

    return resp_body.errorCode, resp_body.errorMessage, result
end

return _M