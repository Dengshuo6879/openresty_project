--[[
网关域名以及服务器地址管理访问模块

关键实现依赖：
1、DB层面的访问，依赖于GwDomainDB
2、Redis层面的访问，依赖于GwDomainRedis
--]]

--统一在文件头部require所需要的依赖模块
local cjson = require "cjson.safe"

--错误码定义
local errorcode = require "errorcode"
--错误信息定义
local errormessage = require "errormessage"

local ClsNameDB = require "saveNameDB"

local _CLASS = {}

--[[
构造函数

输入参数
    obj 构造参数，可以为nil

return
    本Class的对象实例
--]]
function _CLASS:new(obj)
    obj = obj or {}

    --网关域名DB DAO对象
    obj._name_db = ClsNameDB:new()
    --网关域名Redis DAO对象

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
    self._name_db:release()
end

--[[
保存网关集群的域名
与 GwDomainDB 提供的同名函数保持一致的接口规格，直接代理调用
]]
function _CLASS:SaveName(dsNameUUID, 
                        dsName)
    return self._name_db:savedsName(dsNameUUID, dsName)
end

return _CLASS