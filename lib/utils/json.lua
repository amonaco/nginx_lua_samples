-- Simple JSON parsing for Lua 5.1+
-- Minimal implementation focusing on common use cases

local json = {}

function json.decode(str)
    -- For production, use a proper JSON library
    -- This is a simple parser for basic JSON structures
    local ok, result = pcall(function()
        -- Try loadstring/load for simple JSON
        local func
        if _VERSION == "Lua 5.1" then
            func = loadstring("return " .. str)
        else
            func = load("return " .. str)
        end
        if func then
            return func()
        end
    end)
    return ok and result or nil
end

function json.encode(data)
    -- For production, use a proper JSON library
    if type(data) == "string" then
        return '"' .. data:gsub('"', '\\"') .. '"'
    elseif type(data) == "number" then
        return tostring(data)
    elseif type(data) == "boolean" then
        return data and "true" or "false"
    elseif type(data) == "table" then
        local items = {}
        for k, v in pairs(data) do
            if type(k) == "string" then
                table.insert(items, json.encode(k) .. ":" .. json.encode(v))
            end
        end
        return "{" .. table.concat(items, ",") .. "}"
    else
        return "null"
    end
end

return json
