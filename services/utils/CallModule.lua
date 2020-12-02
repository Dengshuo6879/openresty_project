--[[
根据指定的模块名称、方法名称、参数名称列表，将HTTP请求转换成模块的方法调用
--]]

--统一在文件头部require所需要的依赖模块

local cjson = require "cjson.safe"
local ngx_re_split = (require "ngx.re").split

--错误码定义
local errorcode = require "errorcode"
--错误信息定义
local errormessage = require "errormessage"

local callsvc = require "callsvc"
local subsysaddrsconf = require "subsysaddrsconf"

--接口URI路由配置
local routeconf = require "routeconf"

local LOAD_AND_CALL_TEMPLATE = 
    [[
    local cjson = require "cjson.safe"

    --加载指定的模块
    local ClsModule = require "@moduleName"
    local module = ClsModule:new()

    --请求报文体
    --ngx.req.read_body()
    local request_body = ngx.req.get_body_data()
    local request_body_obj = cjson.decode(request_body)

    --调用指定的方法
    --传入指定的参数
    local errorCode, errorMessage, result =
        module:@methodName(@requestParams)

    --释放所占用的系统资源，比如将连接放回DB/Redis连接池
    module:release()

    return errorCode, errorMessage, result
    ]]


local _CLASS = {}

--[[
构造函数
obj
    构造参数，可以为nil

return
    本Class的对象实例
]]
function _CLASS:new(routeConf, obj)
    obj = obj or {}

    --若不指定URI路由配置对象，则使用默认的routeconf.lua
    obj._routeconf = routeConf or routeconf

    --与当前URI倒数第二段对应的模块对象
    obj._curModule = nil

    self.__index = self
    setmetatable(obj, self)
    return obj
end

function _CLASS:_getModuleAndMethodNameConf()
    --获得HTTP请求的URI
    local cur_uri = ngx.var.uri
    --根据"/"，切分URL
    local res = ngx_re_split(cur_uri, "/")

    --URI中最后一段为模块的方法名称
    local methodName = res[#res]
    
    --URI中倒数第二段需要映射为模块名称
    local module_in_uri = res[#res -1 ]
    local moduleName = (self._routeconf[module_in_uri] or {}).MODULE_NAME

    --从配置文件中找到 methodName 对应的函数参数名称列表
    local requestParamNameList = 
        (((self._routeconf[module_in_uri] or {}).SERVICES or {})[methodName] or {}).REQ_PARAMS or {}

    local checkParamRuleList = 
        (((self._routeconf[module_in_uri] or {}).SERVICES or {})[methodName] or {}).CHECK_PARAMS or {}

    --URI中没有指定模块或方法
    if not moduleName or not methodName then
        ngx.status = 400
        ngx.say(cjson.encode{
            errorCode = errorcode.INPUT_WRONG,
            errorMessage = "unsurported uri: " .. cur_uri
        })
        ngx.eof()
        ngx.exit(400)
    end

    --URI中指定了模块和方法，但找不到对应的路由配置
    if not self._routeconf[module_in_uri] or not ((self._routeconf[module_in_uri] or {}).SERVICES or {})[methodName] then
        ngx.status = 400
        ngx.say(cjson.encode{
            errorCode = errorcode.INPUT_WRONG,
            errorMessage = "unsurported uri: " .. cur_uri
        })
        ngx.eof()
        ngx.exit(400)
    end

    return moduleName, methodName, requestParamNameList, checkParamRuleList

end

function _CLASS:check()

    --读取POST请求报文体
    ngx.req.read_body()

    --[[
    判断当前URI是否为代理方式
    ]]
    --获得HTTP请求的URI
    local cur_uri = ngx.var.uri
    --根据"/"，切分URL
    local res = ngx_re_split(cur_uri, "/")
    
    --URI中倒数第二段需要映射为模块名称
    local module_in_uri = res[#res - 1]

    local errorCode, errorMessage, result
    if (self._routeconf[module_in_uri] or {}).IS_PROXY then
        --直接代理方式，不进行参数校验
        --由最终被调用的子系统负责接口参数校验
    else
        --调用调用模块的方法
        errorCode, errorMessage, result = 
        self:_innerCheck()
    end
end

function _CLASS:_innerCheck()

    local moduleName, methodName, requestParamNameList, checkParamRuleList = 
        self:_getModuleAndMethodNameConf()

    --获得请求报文体
    local request_body = ngx.req.get_body_data()
    local request_body_obj = (cjson.decode(request_body) or {})

    self:_check_param_list(request_body_obj, checkParamRuleList)
end

function _CLASS:_check_param_list(request_body_obj, checkParamRuleList)

    for param_name, param_rule in pairs(checkParamRuleList) do

        local cur_checked_param = request_body_obj[param_name]

        if type(param_rule) == "string" and param_rule == "Value" then

            --若当前参数校验规则为"Value"的判断，则仅仅判断是否为nil或者空字符串
            if not cur_checked_param or cur_checked_param == "" then
                ngx.log(ngx.DEBUG, "param_name: ", param_name)
                ngx.log(ngx.DEBUG, [[not cur_checked_param or cur_checked_param == ""]])
                ngx.status = 400
                local response_body = {
                    errorCode = errorcode.INPUT_WRONG,
                    errorMessage = 
                        errormessage.MSG_REQUEST_PARAMS_WRONG .. " " .. param_name .. " is lost"
                }
                ngx.say(cjson.encode(response_body))
                ngx.eof()
            end
        else
            --若当前参数校验规则为一个空table对象，则表示为一个数组，仅判断数组是否为空
            if type(param_rule) == "table" and param_rule.TYPE == "Array" then
                if not cur_checked_param or #cur_checked_param == 0 then
                    ngx.log(ngx.DEBUG, "param_name: ", param_name)
                    ngx.log(ngx.DEBUG, [[not cur_checked_param or #cur_checked_param == 0]])
                    ngx.status = 400
                    local response_body = {
                        errorCode = errorcode.INPUT_WRONG,
                        errorMessage = 
                            errormessage.MSG_REQUEST_PARAMS_WRONG .. " " .. param_name .. " is lost"
                    }
                    ngx.say(cjson.encode(response_body))
                    ngx.eof()
                end
            end

            --若当前参数校验规则为一个非table对象，则表示为一个对象，需要递归判断对象中的下一级字段
            if type(param_rule) == "table" and param_rule.TYPE == "Object" then

                if not cur_checked_param then
                    ngx.log(ngx.DEBUG, "param_name: ", param_name)
                    ngx.log(ngx.DEBUG, [[not not cur_checked_param]])
                    ngx.status = 400
                    local response_body = {
                        errorCode = errorcode.INPUT_WRONG,
                        errorMessage = 
                            errormessage.MSG_REQUEST_PARAMS_WRONG .. " " .. param_name .. " is lost"
                    }
                    ngx.say(cjson.encode(response_body))
                    ngx.eof()
                    ngx.exit(400)
                end

                self:_check_param_list(cur_checked_param, param_rule)
            end
        end
    end

end

function _CLASS:call()

    --[[
    判断当前URI是否为代理方式
    ]]
    --获得HTTP请求的URI
    local cur_uri = ngx.var.uri
    --根据"/"，切分URL
    local res = ngx_re_split(cur_uri, "/")
    
    --URI中倒数第二段需要映射为模块名称
    local module_in_uri = res[#res - 1]

    local errorCode, errorMessage, result
    if (self._routeconf[module_in_uri] or {}).IS_PROXY then
        --直接代理方式

        --ngx.req.read_body()
        local request_body = ngx.req.get_body_data()
        local request_body_obj = cjson.decode(request_body) or {}
        local subSystemName = (self._routeconf[module_in_uri] or {}).SUB_SYS_NAME or "UNKOWN"
        local notIncludedList = (self._routeconf[module_in_uri] or {}).NOT_INCLUDE_PARAMS or {}
        local extraParams = (self._routeconf[module_in_uri] or {}).EXTRA_PARAMS or {}
        local changedNameParams = (self._routeconf[module_in_uri] or {}).CHANGED_NAME_PARAMS or {}

        errorCode, errorMessage, result = 
        self:_proxyCall(request_body_obj, 
                        subSystemName, 
                        notIncludedList, 
                        extraParams, 
                        changedNameParams)
    else
        --调用调用模块的方法
        errorCode, errorMessage, result = 
        self:_innerCall()
    end

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
    cjson.encode_empty_table_as_object(false)
    local response_body = cjson.encode(response_body_obj)

    --设置HTTP应答码
    if errorCode == errorcode.SUCCESS then
        ngx.status = 200
    elseif errorCode == errorcode.INNER_ERR then
        ngx.status = 500
    else
        ngx.status = 400
    end

    --发送应答报文体
    ngx.say(response_body)
    ngx.eof()

end

--[[
直接调用当前URI对应的模块和方法
倒数第二段为模块，倒数第一段为方法
]]
function _CLASS:_innerCall()

    local moduleName, methodName, requestParamNameList = 
        self:_getModuleAndMethodNameConf()

    local load_and_call_str = 
        ngx.re.gsub(LOAD_AND_CALL_TEMPLATE, 
                    [[@moduleName]], moduleName)
    load_and_call_str = 
        ngx.re.gsub(load_and_call_str, 
                    [[@methodName]], methodName)

    --构建调用模块方法时的输入参数模板内容
    --需要确保按指定的参数顺序进行填入
    local requestParams = ""
    for i, param_name in ipairs(requestParamNameList) do
        local curParamStr = "(request_body_obj or {})" .. "." ..  param_name
        requestParams = requestParams .. curParamStr
        if i < #requestParamNameList then
            requestParams = requestParams .. ","
        end
    end
    load_and_call_str = 
        ngx.re.gsub(load_and_call_str, 
                    [[@requestParams]], requestParams)

    ngx.log(ngx.DEBUG, load_and_call_str)
    
    --动态调用替换好内容的代码
    --load_and_call_str = [[return 0, ""]]
    local errorCode, errorMessage, result = load(load_and_call_str)()
    
    return errorCode, errorMessage, result
   
end

--[[
将URI代理到指定子系统的对应HTTP L1服务上，URI保持不变
]]
function _CLASS:_proxyCall(request_body_obj, 
                           subSystemName, 
                           notIncludedList, 
                           extraParams,
                           changedNameParams)

    --从子系统服务地址配置文件中获得地址列表
    local addr_list = subsysaddrsconf[subSystemName] or {}
    --直接代理时，URI保持不变
    local req_url = ngx.var.uri
    local body = request_body_obj

    --过滤掉不需要的输入参数
    for i, v in ipairs(notIncludedList) do
        body[v] = nil
    end

    --加入额外增加的输入参数
    for k, v in pairs(extraParams) do
        body[k] = v
    end

    --替换需要变更字段名称的输入参数
    for k, v in pairs(changedNameParams) do
        body[v] = body[k]
        body[k] = nil
    end

    ngx.log(ngx.DEBUG, "addr_list: ", cjson.encode(addr_list))
    ngx.log(ngx.DEBUG, "req_url: ", req_url)
    ngx.log(ngx.DEBUG, "body: ", cjson.encode(body))

    --代理调用
    local errorCode, errorMessage, result = 
        callsvc:callSvc(addr_list, req_url, body)

    ngx.log(ngx.DEBUG, "callsvc:callSvc(addr_list, req_url, body)")
    ngx.log(ngx.DEBUG, errorCode, errorMessage)

    return errorCode, errorMessage, result
end

return _CLASS