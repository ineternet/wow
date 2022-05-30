setfenv(1, require(script.Parent.Global))

local TargetUnit = use"WorldUnit".inherit"TargetUnit"

--Unit class that can target and be targeted and have auras.

TargetUnit.new = Constructor(TargetUnit, {
    display = "",
    target = nil,

    auras = {},

    charsheet = use"Charsheet".new,
}, function(self)
    self.charsheet.unit = self
end)

TargetUnit.hasAura = function(self, auradef)
    for i, aura in ipairs(self.auras) do
        if aura.aura == auradef and not aura.invalidate then
            return true
        end
    end
    return false
end

TargetUnit.tick = function(self, deltaTime)
    local toRemove = {}
    for i, aura in ipairs(self.auras) do
        if aura.invalidate then
            for _, event in ipairs(aura.eventConnections) do
                event:Disconnect()
            end
            table.insert(toRemove, i)
        else
            aura:tick(deltaTime, self)
        end
    end
    for _, i in ipairs(toRemove) do
        table.remove(self.auras, i)
    end
end

TargetUnit.auraStatFlat = function(self, stat)
    local value = 0
    for _, aura in ipairs(self.auras) do
        if aura.statFlat and aura.statFlat[stat] then
            value = value + aura.statFlat[stat]
        end
    end
    return value
end

TargetUnit.auraStatMod = function(self, stat)
    local value = 1
    for _, aura in ipairs(self.auras) do
        if aura.statMod and aura.statMod[stat] then
            value = value * (1 + aura.statMod[stat])
        end
    end
    return value
end

return TargetUnit