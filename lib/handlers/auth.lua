-- Authentication handler
-- Validates requests via custom headers (X-Foo-Id, X-Foo-Key)
-- Uses Redis to verify credentials
--
-- Usage: access_by_lua_file /path/to/handlers/auth.lua

local redis_client = require 'middleware.redis_client'
local logger = require 'middleware.logger'

local function authenticate()
    local headers = ngx.req.get_headers()
    local id = headers["x-foo-id"]
    local key = headers["x-foo-key"]
    
    if not id or not key then
        logger.warn("Missing credentials for " .. ngx.var.remote_addr)
        return false, "Missing authentication headers"
    end
    
    local client = redis_client.get_connection()
    if not client then
        logger.error("Failed to connect to Redis")
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    
    local ok, secret = pcall(function()
        return client:get(id)
    end)
    
    if not ok then
        logger.error("Redis error: " .. tostring(secret))
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    
    if secret ~= key then
        logger.warn("Invalid credentials for id=" .. id .. " from " .. ngx.var.remote_addr)
        return false, "Invalid credentials"
    end
    
    logger.info("Authenticated: id=" .. id)
    ngx.ctx.user_id = id  -- Store for later use
    return true
end

local ok, err = authenticate()
if not ok then
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end
