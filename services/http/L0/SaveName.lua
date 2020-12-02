--[[
SaveGWDomainName 接口的服务处理入口

关键实现依赖：
1、依赖 GwDomainModule 模块提供本接口的具体实现
--]]

--统一在文件头部require所需要的依赖模块

local cjson = require "cjson.safe"

--错误码定义
local errorcode = require "errorcode"
--错误信息定义
local errormessage = require "errormessage"

--网关域名信息管理和访问模块
local ClsGwModule = require "NameModule"
local gw_module = ClsGwModule:new()

--请求报文体
ngx.req.read_body()
local request_body = ngx.req.get_body_data()

local request_body_obj = cjson.decode(request_body)

--调用 GwDomainModule 对象的对应函数
local errorCode, errorMessage, result =
    gw_module:SaveName(request_body_obj.dsNameUUID,
                               request_body_obj.dsName)

--组装应答报文体
local response_body_obj = {
    errorCode = errorCode,
    errorMessage = errorMessage
}
if result then
    for k, v in pairs(result) do
        response_body_obj[k] = v
    end
end
local response_body = cjson.encode(response_body_obj)

--发送应答报文体
ngx.say(response_body)

--设置HTTP应答码
if errorCode == errorcode.SUCCESS then
    ngx.exit(200)
elseif errorCode == errorcode.INNER_ERR then
    ngx.exit(500)
else
    ngx.exit(400)
end
