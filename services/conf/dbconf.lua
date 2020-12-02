--[[
  DB连接配置信息
]]

local conf = {
  host = "127.0.0.1",
  port = 3306,
  database = "ds_database",
  user = "dsopdev",
  password = "DsopDev@mysql123",
  charset = "utf8",
  max_packet_size = 1024 * 1024
}

return conf