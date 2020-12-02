--[[
各子系统L1接口的相对URL，不包含前缀
]]

local conf = {

    --访问控制中心的相关L1接口
    CreateConsumerOnGW = "/Provision/CreateConsumerOnGW",

    --基础设施服务的相关L1接口
    SendMail = "Mail/SendMail"
}

return conf