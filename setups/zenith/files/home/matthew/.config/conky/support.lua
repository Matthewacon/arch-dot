---@diagnostic disable: lowercase-global
function conky_getweekday()
    return string.upper(tostring(os.date("%A")):gsub(".", "%1 "):sub(1, -2))
end

function conky_getdate()
    return string.upper(tostring(os.date("%d %B, %Y")))
end

function conky_gettime()
    return string.upper(tostring(os.date("- %H:%M -")))
end

function conky_passthrough(a)
    return a
end
