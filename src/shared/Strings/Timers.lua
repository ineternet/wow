local Timers = {}

Timers.AuraTimer = function(seconds)
    --Return a string that represents the time up to weeks, for aura display.
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm", seconds / 60)
    elseif seconds < 86400 then
        return string.format("%dh", seconds / 3600)
    elseif seconds < 604800 then
        return string.format("%dd", seconds / 86400)
    else
        return string.format("%dw", seconds / 604800)
    end
end

return Timers
