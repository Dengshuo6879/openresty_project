--[[
接口URI的路由配置
]]

local conf = {

}


conf["DSApiMgr"] = {
    MODULE_NAME = "NameModule",
    SERVICES = {
    }
}

-- 2.1.保存网关集群的域名
conf["DSApiMgr"].SERVICES["SaveName"] = {
    REQ_PARAMS = {
        "dsNameUUID",
        "dsName"
    },
    CHECK_PARAMS = {
        gwDomainName = "Value"
    }
}

return conf