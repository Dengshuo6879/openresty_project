--统一在文件头部require所需要的依赖模块
local cjson = require "cjson.safe"
local uuid = require "resty.jit-uuid"

--本Class对应的SQL语句模块
local sqls = require "saveNameSQL"
--错误码定义
local errorcode = require "errorcode"
--错误信息定义
local errormessage = require "errormessage"
--项目目前的运行模式
local pjm = require "projectmode"

local ClsDbDao = require "DbDao"
local _CLASS = {}

--[[
构造函数
obj
    构造参数，可以为nil

return
    本Class的对象实例
]]
function _CLASS:new(obj)
    obj = obj or {}

    obj._dbdao = ClsDbDao:new()
    self.__index = self
    setmetatable(obj, self)

    return obj
end

--[[
释放必要的系统资源

return
    操作成功与否的标志
]]
function _CLASS:release()
    return self._dbdao:release()
end

function _CLASS:savedsName(dsNameUUID, 
                            dsName)

    if not dsNameUUID or dsNameUUID == "" then
        if pjm.NOW == "dev" then
            uuid.seed()
        end
        dsNameUUID = uuid()
    end

    --替换SAVE SQL语句的参数
    local save_sql = ngx.re.gsub(sqls.SAVE, [[@dsNameUUID]], dsNameUUID)
    save_sql = ngx.re.gsub(save_sql, [[@dsName]], dsName)

    --执行SAVE SQL语句
    local res, err, errcode, sqlstate =
        self._dbdao._db:query(save_sql)
    if not res then
        ngx.log(ngx.ERR, save_sql)
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
        return errorcode.INNER_ERR, errormessage.MSG_DB_INSERT_OR_UPDATE_ERR
    end

    --调试用
    --ngx.say(cjson.encode(res))
    --ngx.exit(200)

    --替换 QUERY_DOMAIN_STATUS SQL语句的参数
    -- local domain_status_sql = 
    --     ngx.re.gsub(sqls.QUERY_DOMAIN_STATUS, 
    --                 [[@dsNameUUID]], 
    --                 dsNameUUID)

    -- --执行 QUERY_DOMAIN_STATUS SQL语句
    -- local res, err, errcode, sqlstate =
    --     self._dbdao._db:query(domain_status_sql)
    -- if not res then
    --     ngx.log(ngx.ERR, domain_status_sql)
    --     ngx.log(ngx.ERR, "bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    --     return errorcode.INNER_ERR, errormessage.MSG_DB_SELECT_ERR
    -- end

    --基于查询结果，构造 dsNameStatus 对象
    local result = {
        dsNameStatus = {
            dsNameUUID = dsNameUUID,
        }
    }

    return errorcode.SUCCESS, "", result
end


return _CLASS