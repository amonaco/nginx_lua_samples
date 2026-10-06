-- String manipulation utilities
-- Compatible with Lua 5.1+

local string_utils = {}

function string_utils.split(str, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]+)"
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    return result
end

function string_utils.trim(str)
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function string_utils.starts_with(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

function string_utils.ends_with(str, suffix)
    return string.sub(str, -string.len(suffix)) == suffix
end

function string_utils.url_decode(str)
    str = string.gsub(str, "+", " ")
    str = string.gsub(str, "%%(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end)
    return str
end

return string_utils
