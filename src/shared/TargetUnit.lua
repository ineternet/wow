setfenv(1, require(script.Parent.Global))

local TargetUnit = use"WorldUnit".inherit"TargetUnit"

--Unit class that can target and be targeted and have auras.

TargetUnit.new = Constructor(TargetUnit, {
    display = "",
    target = nil,

    auras = {}, --Auras this unit is affected by
    castAuras = {}, --Auras this unit has cast on others/itself

    charsheet = use"Charsheet".new,
})

TargetUnit.hasAura = function(self, auradef, byCauser)
    assertObj(auradef)
    auradef:assertIs("Aura")
    assert(byCauser == nil or (byCauser.is and byCauser:is("Unit")), "byCauser must be a unit or nil")

    return self:findFirstAura(auradef, byCauser) ~= nil
end

TargetUnit.findFirstAura = function(self, auradef, byCauser)
    assertObj(auradef)
    auradef:assertIs("Aura")
    assert(byCauser == nil or (byCauser.is and byCauser:is("Unit")), "byCauser must be a unit or nil")

    for i, aura in ipairs(self.auras.noproxy) do
        local cond = true
        if byCauser then
            cond = aura.causer and aura.causer:ReferenceEquals(byCauser)
        end
        if aura.aura.id == auradef.id and not aura.invalidate and cond then
            return aura
        end
    end
    return nil
end

TargetUnit.isFriendly = function(self, unit)
    return unit.target == self
end

TargetUnit.isEnemy = function(self, unit)
    return not self:isFriendly(unit)
end

TargetUnit.tick = function(self, deltaTime)
    local auras = self.auras.noproxy
    for i, _ in ipairs(auras) do
        --TODO: noproxy generates a clone, so we can use it for iterating,
        --but not for mutation. Either make a unified iterator or dont clone in noproxy
        local aura = self.auras[i]
        if aura.invalidate then
            for _, event in ipairs(aura.eventConnections) do
                event:Disconnect()
            end
            use"Spell".RemoveAuraInstance(self, aura)
        else
            aura:tick(deltaTime, self)
        end
    end

    TargetUnit.super.tick(self, deltaTime)
end

TargetUnit.auraStatFlat = function(self, stat)
    local value = 0
    for _, auraInstance in ipairs(self.auras.noproxy) do
        if auraInstance.aura.statFlat and auraInstance.aura.statFlat[stat] then
            value = value + auraInstance.aura.statFlat[stat]
        end
    end
    return value
end

TargetUnit.auraStatMod = function(self, stat)
    local value = 1
    for _, auraInstance in ipairs(self.auras.noproxy) do
        if auraInstance.aura.statMod and auraInstance.aura.statMod[stat] then
            value = value * (1 + auraInstance.aura.statMod[stat])
        end
    end
    return value
end

return TargetUnit