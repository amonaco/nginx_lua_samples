local num = tonumber(ngx.var.arg_num) or 0
local redis = require 'redis'
local params = { host = '127.0.0.1', port = 6379 }

if num > 30 then
    ngx.say("num too big")
    return
end

-- bar
local client = redis.connect(params)
client:select(15)
client:set('foo', 'bar')
local value = client:get('foo')

ngx.say("num is: ", num)
ngx.say("bar is: ", value)
ngx.say("uri: ", ngx.var.uri)
ngx.say("uri: ", ngx.var.lua_need_request_body)

if num > 0 then
    res = ngx.location.capture("/recur?num=" .. tostring(num - 1))
    ngx.print("status=", res.status, " ")
    ngx.print("body=", res.body)
else
    ngx.say("end")
end
