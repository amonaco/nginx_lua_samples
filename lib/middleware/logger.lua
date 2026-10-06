-- Logging utilities
-- Wraps ngx.log with level-based functions

local logger = {}

local LOG_LEVEL = {
    DEBUG = ngx.DEBUG,
    INFO = ngx.INFO,
    WARN = ngx.WARN,
    ERR = ngx.ERR,
    CRIT = ngx.CRIT,
    ALERT = ngx.ALERT,
    EMERG = ngx.EMERG
}

local function format_message(level, msg)
    return "[" .. level .. "] " .. msg
end

function logger.debug(msg)
    ngx.log(LOG_LEVEL.DEBUG, format_message("DEBUG", msg))
end

function logger.info(msg)
    ngx.log(LOG_LEVEL.INFO, format_message("INFO", msg))
end

function logger.warn(msg)
    ngx.log(LOG_LEVEL.WARN, format_message("WARN", msg))
end

function logger.error(msg)
    ngx.log(LOG_LEVEL.ERR, format_message("ERROR", msg))
end

return logger
