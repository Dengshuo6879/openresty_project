--[[
DB DAO基础类

关键实现依赖：
1、DB连接配置信息，来自services/conf/dbconf.lua
--]]

--统一在文件头部require所需要的依赖模块
local mysql = require "resty.mysql"
local uuid = require 'resty.jit-uuid'

--错误码定义
local errorcode = require "errorcode"
--错误信息定义
local errormessage = require "errormessage"

--DB连接配置
local dbconf = require "dbconf"

local _CLASS = {}

--DB事务操作的SQL语句
local BEGIN_SQL = "START TRANSACTION;"
local COMMIT_SQL = "COMMIT;"
local ROLLBACK_SQL = "ROLLBACK;"

--[[
构造函数
obj
    构造参数，可以为nil

return
    本Class的对象实例
]]
function _CLASS:new(obj)
    obj = obj or {}

    --连接mysql
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.CRIT, "mysql:new() is failed.")
        return nil
    end

    local ok, err, errcode, sqlstate = db:connect(dbconf)
    if not ok then
        ngx.log(ngx.CRIT, "failed to connect: ", err, ": ", errcode, " ", sqlstate)
        return nil
    end

    obj._db = db
    obj._db:set_timeout(5000) -- 1 sec

    self.__index = self
    setmetatable(obj, self)
    return obj
end


--[[
释放必要的系统资源
return
    操作成功与否的标志
--]]
function _CLASS:release()

    --local ok, err = self._db:set_keepalive()
    local ok, err = self._db:close()
    if not ok then
        ngx.log(ngx.WARN, "failed to close: ", err)
        return false
    end
    return true

end

--[[
操作DB事务
]]
function _CLASS:_dbTranOperate(sql)

    local res, err, errcode, sqlstate =
            self._db:query(sql)
    if not res then
        ngx.log(ngx.ERR, sql)
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
        return errorcode.INNER_ERR, errormessage.MSG_DB_TRANSCATION_ERR
    end

    return errorcode.SUCCESS, ""

end

--[[
开始DB事务
]]
function _CLASS:beginTran()
    return self:_dbTranOperate(BEGIN_SQL)
end

--[[
回滚DB事务
]]
function _CLASS:rollBackTran()
    return self:_dbTranOperate(ROLLBACK_SQL)
end

--[[
提交DB事务
]]
function _CLASS:commitTran()
    return self:_dbTranOperate(COMMIT_SQL)
end

return _CLASS