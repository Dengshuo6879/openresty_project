local begin_now = ngx.now()

local cjson = require "cjson.safe"
--错误码定义
local errorcode = require "errorcode"
--错误信息定义
local errormessage = require "errormessage"

local ngxcontext = require "ngxcontext"

local routeconfL0 = require "routeconfL0"
local ClsCallModule = require "CallModule"

--[[
-- 实例化网关模块
local gwmodule = ClsGwDomainModule:new()
-- 获得远程客户端真实IP地址
-- 远程客户端，即网关
local gwIP = ngxcontext.getRemoteIP()

local errorCode, errorMessage =  gwmodule:QueryGWServerAddrIsExist(gwIP)
-- ip鉴权失败
if errorCode ~= errorcode.SUCCESS then
    ngx.status = 400
    ngx.say(cjson.encode{
        errorCode = errorCode,
        errorMessage = errorMessage
    })
    ngx.eof()
    ngx.exit(400)
end
]]

local callmodule = ClsCallModule:new(routeconfL0)
callmodule:call()
local end_now = ngx.now()
ngx.log(ngx.DEBUG, "time spand: ", (end_now - begin_now)*1000, "ms")