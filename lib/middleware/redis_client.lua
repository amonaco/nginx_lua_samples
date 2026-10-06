-- Redis client connection management
-- Provides connection pooling and error handling
-- Compatible with multiple Lua versions (5.1, 5.2, 5.3)

local redis_client = {}

-- Cache connection per worker process
local connection_cache = {}

local function create_connection()
    local redis = require 'redis'
    
    local host = os.getenv('REDIS_HOST') or '127.0.0.1'
    local port = tonumber(os.getenv('REDIS_PORT') or 6379)
    local timeout = tonumber(os.getenv('REDIS_TIMEOUT') or 1000)
    
    local params = {
        host = host,
        port = port,
        timeout = timeout
    }
    
    -- Unix socket support
    local redis_sock = os.getenv('REDIS_SOCKET')
    if redis_sock then
        params = { path = redis_sock, timeout = timeout }
    end
    
    local client = redis.connect(params)
    if not client then
        return nil, "Failed to connect to Redis"
    end
    
    return client
end

function redis_client.get_connection()
    -- Use ngx.var.pid if available (nginx context)
    local worker_id = ngx.worker.pid and tostring(ngx.worker.pid()) or "single"
    
    if connection_cache[worker_id] then
        return connection_cache[worker_id]
    end
    
    local client, err = create_connection()
    if not client then
        return nil
    end
    
    connection_cache[worker_id] = client
    return client
end

function redis_client.close_connection()
    local worker_id = ngx.worker.pid and tostring(ngx.worker.pid()) or "single"
    if connection_cache[worker_id] then
        pcall(function()
            connection_cache[worker_id]:close()
        end)
        connection_cache[worker_id] = nil
    end
end

return redis_client
