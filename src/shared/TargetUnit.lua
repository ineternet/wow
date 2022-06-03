setfenv(1, require(script.Parent.Global))

local TargetUnit = use"WorldUnit".inherit"TargetUnit"

--Unit class that can target and be targeted and have auras.

TargetUnit.new = Constructor(TargetUnit, {
    display = "",
    target = nil,

    auras = {},

    charsheet = use"Charsheet".new,
}, function(self)
    --self.charsheet = ref(use"Charsheet".new())
    --self.charsheet.unit = ref(self)
end)

TargetUnit.hasAura = function(self, auradef)
    print("CHECKING FOR AURA", auradef)
    print(self.auras)
    print(self.auras.noproxy)
    for i, aura in ipairs(self.auras.noproxy) do
        print("Checking if aura", aura.aura.name, "is", auradef.name)
        if aura.aura.id == auradef.id and not aura.invalidate then
            print"it is"
            return true
        end
    end
    return false
end

TargetUnit.isFriendly = function(self, unit)
    return unit.target == self
end

TargetUnit.isEnemy = function(self, unit)
    return not self:isFriendly(unit)
end

TargetUnit.tick = function(self, deltaTime)
    local toRemove = {}
    local triggerRemove = false
    local auras = self.auras.noproxy
    local printauras = math.random() > 0.99
    for i, aura in ipairs(auras) do
        if printauras then
            print("Server has aura:", aura.aura.name)
        end
        --TODO: noproxy generates a clone, so we can use it for iterating,
        --but not for mutation. Either make a unified iterator or dont clone in noproxy
        local aura = self.auras[i]
        if aura.invalidate then
            for _, event in ipairs(aura.eventConnections) do
                event:Disconnect()
            end
            toRemove[i] = true
            triggerRemove = true
        else
            aura:tick(deltaTime, self)
        end
    end

    if triggerRemove then
        local shift = 0
        local fTop = #auras
        for i = 1, fTop+1 do
            if toRemove[i-1] then
                shift = shift + 1
            end
            if shift > 0 then
                self.auras[i-shift] = self.auras[i]
            end
        end
        for i = fTop-shift+1, fTop do
            self.auras[i] = nil
        end --TODO: May need to finalize each aura to clear connections
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