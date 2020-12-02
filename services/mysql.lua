-- Copyright (C) 2018 by chrono

-- curl 127.1:81/mysql

local mysql = require "resty.mysql"

local db, err = mysql:new()
if not db then
    ngx.say("new msyql failed : ", err)
    return
end

db:set_timeout(1000)

local opts = {
    host = "127.0.0.1",
    port = 3306,
    database = 'ds_database',
    user = 'dsopdev',
    password = 'DsopDev@mysql123',
    }

local ok, err = db:connect(opts)
if not ok then
    ngx.say("connect msyql failed : ", err)
    db:close()
    return
end

ngx.say("db ver : ", db:server_ver())

local res, err, errcode, sqlstate

res, err = db:query("drop table if exists dsop_user")

res, err = db:query("create table dsop_user(dsNameUUID char(20), dsName char(20))")

res, err = db:query("insert into dsop_user values('1234-5678', '邓硕')")

--ngx.say(res.insert_id, res.affected_rows)

-- res, err = db:query("insert into test(name) values('nginx')")



res, err = db:query("select * from dsop_user", 5)

for i,rows in ipairs(res) do
    ngx.print("No.", i, " : ")
    for k,v in pairs(rows) do
        ngx.print(k, " = ", v, ";")
    end
    ngx.say()
end

res, err = db:send_query("select 1;select 2")

local cjson = require "cjson.safe"
repeat
    res, err = db:read_result()
    if not res then
        ngx.say("query failed : ", err)
        ngx.exit(500)
    end
    ngx.say(cjson.encode(res))
until err ~= 'again'

local str = "';show tables"
ngx.say(ngx.quote_sql_str(str))


db:close()
