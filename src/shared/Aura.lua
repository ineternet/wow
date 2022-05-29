setfenv(1, require(script.Parent.Global))

local Aura = use"Object".inherit"Aura"
local AuraInstance = use"Object".inherit"AuraInstance"

local function auraDummy(spell, castingUnit, spellTarget, spellLocation)

end

AuraInstance.tick = function(self, deltaTime, owner)
    if self.invalidate then
        return
    end

    if not self.elapsedPart then
        self.elapsedPart = 0
    end

    local hasted = 1
    if self.aura.affectedByCauserHaste
    and self.causer
    and self.causer.charsheet
    and self.causer.charsheet.haste then
        hasted = 1 + self.causer.charsheet:haste()
    end

    
    local lastTick = false
    if self.elapsedPart >= 1 then
        self.invalidate = true
        lastTick = true
    end

    if self.aura.onTick then
        local ticks = self.duration --One tick per second
        if not self.remainingTicks then
            self.remainingTicks = ticks
        end
        local nextLogicalTick = (1 + (ticks - self.remainingTicks)) / ticks
        local partialTick = 1
        if nextLogicalTick > 1 and self.remainingTicks == 1 then
            partialTick = (1 - nextLogicalTick) * ticks
        end
        if self.elapsedPart >= nextLogicalTick then
            self.remainingTicks = self.remainingTicks - 1
            --print("Ticking aura now. Remaining ticks: " .. self.remainingTicks .. ", Partial tick: " .. partialTick, ", Elapsed since start: " .. (utctime() - self.appliedAt))
            self.aura.onTick(self, deltaTime, owner, partialTick)
        end
    end

    --print("Added to part:", (deltaTime / self.duration) * hasted, "Haste modifier:", hasted)
    self.elapsedPart = self.elapsedPart + (deltaTime / self.duration) * hasted
end

Aura.createInstance = function(self)
    local aura = AuraInstance.new()
    aura.aura = self
    aura.appliedAt = utctime()
    return aura
end

AuraInstance.new = Constructor(AuraInstance, {})
Aura.new = Constructor(Aura, {
    effectType = AuraEffectType.None, --Default effect type is none.
})

Auras.MortalWounds = Aura.new()
Auras.MortalWounds:assign({
    name = "Mortal Wounds",
    tooltip = function(sheet)
        local str = "Received healing is reduced by %s."
        return str
    end,
    icon = "rbxassetid://1337",
    onIncomingHeal = function(aura, refHeal)
        refHeal.amount = refHeal.amount * 0.5
    end,
})

Auras.PyroblastDot = Aura.new()
Auras.PyroblastDot:assign({
    name = "Pyroblast",
    tooltip = function(sheet)
        local str = "%s Fire damage inflicted every %ssec."
        return str
    end,
    icon = "rbxassetid://1337",
    onTick = function(aura, deltaTime, owner, tickStrength)
        owner:takeDamage((aura.damage(aura.causer.charsheet) / aura.duration) * tickStrength, Schools.Fire)
    end,
    effectType = AuraEffectType.Magic,
    affectedByCauserHaste = true,
    --baseTicks = 8,
})

Auras.FlamestrikeSlow = Aura.new()
Auras.FlamestrikeSlow:assign({
    name = "Flamestrike",
    tooltip = function(sheet)
        local str = "Movement speed reduced by %s%%."
        return str
    end,
    icon = "rbxassetid://1337",
    statMod = {
        speed = -0.2,
    }
})

return Aura