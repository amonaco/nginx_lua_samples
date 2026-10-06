-- Rate limiting handler
-- Implements token-bucket style rate limiting using Redis
--
-- Usage: access_by_lua_file /path/to/handlers/limit.lua
-- Configure limits in Redis: SET user_limit 100

local redis_client = require 'middleware.redis_client'
local logger = require 'middleware.logger'

local function get_user_id()
    -- From auth handler or fall back to IP
    return ngx.ctx.user_id or ngx.var.remote_addr
end

local function check_limit(user_id, limit_key)
    local client = redis_client.get_connection()
    if not client then
        logger.error("Failed to connect to Redis")
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    
    local ok, results = pcall(function()
        -- Use transaction for atomic operations
        return client:transaction(function(t)
            t:get(limit_key)            -- Get current count
            t:get(limit_key .. "_max") -- Get max limit
            t:incr(limit_key)           -- Increment counter
        end)
    end)
    
    if not ok then
        logger.error("Redis transaction failed: " .. tostring(results))
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    
    local current = tonumber(results[1]) or 0
    local max_limit = tonumber(results[2]) or 100
    
    if current >= max_limit then
        logger.warn("Rate limit exceeded for " .. user_id .. ": " .. current .. "/" .. max_limit)
        return false
    end
    
    logger.info("Rate limit OK for " .. user_id .. ": " .. current .. "/" .. max_limit)
    return true
end

local user_id = get_user_id()
local limit_key = "rate_limit:" .. user_id

if not check_limit(user_id, limit_key) then
    return ngx.redirect("/limit_reached.html")
end
