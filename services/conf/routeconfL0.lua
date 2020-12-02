--[[
接口URI的路由配置
]]

local conf = {

}

-- 数据服务API资源的管理和访问
conf["DSApiMgr"] = {
    MODULE_NAME = "NameModule",
    SERVICES = {
    }
}

--保存名字
conf["DSApiMgr"].SERVICES["SaveName"] = {
    REQ_PARAMS = {
        "dsNameUUID",
        "dsName"
    },
    CHECK_PARAMS = {
        dsName = "Value"
    }
}

return conf