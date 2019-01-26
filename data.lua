-- connect to redis
local redis = require 'redis'
local params = { host = '127.0.0.1', port = 6379 }

-- uri params
-- local num = tonumber(ngx.var.arg_num) or 0

-- connection
local client = redis.connect(params)

-- check for headers
local id = ngx.req.get_headers()["x-foo-id"]
local key = ngx.req.get_headers()["x-foo-key"]
if key == nil or id == nil then
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
else
    -- check secret
    local secret = client:get(id)
    if secret ~= key then
        ngx.log(ngx.ERR, "unauthorized connection: ", ngx.var.remote_addr)
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end
end

-- read and get body
ngx.req.read_body()
local body = ngx.req.get_body_data()

-- split uri
local method, object, k, v
for k, v in string.gmatch(ngx.var.uri, "/(%w+)/(%w+)") do
    method = k
    object = v
end

-- build key to save data
local redis_key = id .. ':' .. object

-- simplicity for demo's sake
if method == 'save' then

    -- save data object
    if client:set(redis_key, body) then
        ngx.say('{ "result": "ok" }')
    else
        ngx.say('{ "result": "error" }')
    end
elseif method == 'read' then
    -- read data object
    local data = client:get(redis_key)
    ngx.say('{ "result": '.. data .. '}')
else
    -- everything else yields forbidden
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- never reached
ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
