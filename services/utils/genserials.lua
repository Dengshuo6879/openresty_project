--[[
产生序列号的工具模块
]]

local _M = {}

function _M.genSerialByTime()
    local cur_local_time = ngx.localtime()
    local cur_now = ngx.now()
    math.randomseed(cur_now)
    local cur_random_1 = math.random(1, 999)
    
    -- 不够3位数左边补0
    local cur_random = string.format("%03d", cur_random_1)

    local serial = 
            ngx.re.gsub(cur_local_time, " ", "")
    serial = 
        ngx.re.gsub(serial, "-", "")
    serial = 
        ngx.re.gsub(serial, ":", "")

    --local a, b = math.modf(ngx.now() * 1000)
    local openssl_rand = require "resty.openssl.rand"
    local str_a = openssl_rand.bytes(64)
    str_a = string.format("%012d", ngx.crc32_long(str_a))
    --local str_time = "" .. ngx.time()

    serial = serial .. str_a .. cur_random

    return serial
end

function _M.genSerialByTimeNoDate()

    local cur_now = ngx.now()
    math.randomseed(cur_now)
    local cur_random_1 = math.random(1, 999)
    local cur_random_2 = math.random(1, 999)

    -- 不够3位数左边补0
    local cur_random = string.format("%03d", cur_random_1)

    local serial = ""

    local a, b = math.modf(cur_now * 1000)
    local str_a = "" .. a
    --local str_time = "" .. ngx.time()

    serial = serial .. str_a .. cur_random

    return serial
end

--[[
产生指定长度的ASCII可显示字符字符串
]]
function _M.genRandomSerial(len)

    local cur_now = ngx.now()
    math.randomseed(cur_now)

    local serial = ""
    for i = 1, len do
        local curValue = ""
        local char_seg = math.random(1, 3)
        if char_seg == 1 then
            --产生数字
            curValue = math.random(48, 57)
        end
        if char_seg == 2 then
            --产生@、或大写字母
            curValue = math.random(64, 90)
        end
        if char_seg == 3 then
            --产生小写字母
            curValue = math.random(97, 112)
        end

        
        serial = serial .. string.char(curValue)
    end

    return serial

end

--[[
产生当前时间戳
]]
function _M.getCurDateTime()
    local curDateTime = ngx.localtime()
    local curTimeMSec = ngx.now()
    local a, b = math.modf(curTimeMSec)
    b = b * 1000000
    a, b = math.modf(b)
    curDateTime = curDateTime .. [[.]] .. a

    return curDateTime
end

return _M