local num = tonumber(ngx.var.arg_num) or 0
local redis = require 'redis'
local key = 'xfubar'
local lkey = key .. '_limit' 
local params = { host = '127.0.0.1', port = 6379 }
-- local params = { path = '/tmp/redis.sock' }
local client = redis.connect(params)

-- client:select(11)

local ret = client:transaction(function(t)
    t:get(key) -- before incr
    t:get(lkey)
    t:incr(key)
end)

local calls = table.remove(ret, 1)
local limit = table.remove(ret, 1)

-- check if conf limit set
if limit == nil then
    ngx.say("limit key not found!")
end

-- check if key exists
if calls == nil then
    ngx.say("key not defined!")
end

if calls >= limit then
    return ngx.redirect("/limit_reached.html")
else
    return ngx.redirect("/")
end
