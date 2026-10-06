-- Data persistence handler
-- Provides save/read operations with Redis backend
--
-- Usage: content_by_lua_file /path/to/handlers/data.lua
-- Expects URIs like: /save/{object} or /read/{object}

local redis_client = require 'middleware.redis_client'
local logger = require 'middleware.logger'
local string_utils = require 'utils.string_utils'

local function parse_uri(uri)
    local method, object = string.match(uri, "/(%w+)/(%w+)")
    return method, object
end

local function read_body()
    ngx.req.read_body()
    return ngx.req.get_body_data()
end

local function save_data(user_id, object, data)
    local client = redis_client.get_connection()
    if not client then
        logger.error("Failed to connect to Redis")
        ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
        ngx.say('{"error":"Redis unavailable"}')
        return
    end
    
    local redis_key = user_id .. ':' .. object
    
    local ok, result = pcall(function()
        return client:set(redis_key, data)
    end)
    
    if not ok then
        logger.error("Redis set failed: " .. tostring(result))
        ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
        ngx.say('{"error":"Storage error"}')
        return
    end
    
    logger.info("Saved data: " .. redis_key)
    ngx.status = ngx.HTTP_OK
    ngx.say('{"result":"ok"}')
end

local function read_data(user_id, object)
    local client = redis_client.get_connection()
    if not client then
        logger.error("Failed to connect to Redis")
        ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
        ngx.say('{"error":"Redis unavailable"}')
        return
    end
    
    local redis_key = user_id .. ':' .. object
    
    local ok, data = pcall(function()
        return client:get(redis_key)
    end)
    
    if not ok then
        logger.error("Redis get failed: " .. tostring(data))
        ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
        ngx.say('{"error":"Retrieval error"}')
        return
    end
    
    if not data then
        logger.warn("Data not found: " .. redis_key)
        ngx.status = ngx.HTTP_NOT_FOUND
        ngx.say('{"error":"Not found"}')
        return
    end
    
    logger.info("Retrieved data: " .. redis_key)
    ngx.status = ngx.HTTP_OK
    ngx.say('{"result":' .. data .. '}')
end

local method, object = parse_uri(ngx.var.uri)

if not method or not object then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say('{"error":"Invalid URI format"}')
    return
end

if method == 'save' then
    local data = read_body()
    if not data then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"error":"Empty body"}')
        return
    end
    save_data(ngx.ctx.user_id, object, data)
elseif method == 'read' then
    read_data(ngx.ctx.user_id, object)
else
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.say('{"error":"Method not allowed"}')
end
