setfenv(1, require(script.Parent.Global))

local Aura = use"Object".inherit"Aura"
local AuraInstance = use"Object".inherit"AuraInstance"

local Linebreak = "\n"

local function auraDummy(spell, castingUnit, spellTarget, spellLocation)

end

local function schoolDot(school)
    return function(aura, deltaTime, owner, tickStrength)
        use"Spell".SchoolDamage(aura.spellSource, aura.causer, owner, (aura.damage(aura.causer, aura.causer.charsheet) / aura.duration) * tickStrength, school, 1)
    end
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
        hasted = 1 + self.causer.charsheet:haste(owner)
    end

    
    local lastTick = false
    if self.elapsedPart >= 1 then
        self.invalidate = true
        lastTick = true
    end

    if self.aura.onTick then
        local tickTimeout = 1 --Seconds between ticks
        local ticks = self.duration / tickTimeout
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
            self.aura.onTick(self, deltaTime, owner, partialTick)
        end
    end

    self.elapsedPart = self.elapsedPart + (deltaTime / self.duration) * hasted
end

AuraInstance.remainingTime = function(self)
    if not self.duration then --We assume unset duration means the aura is permanent
        return math.huge
    end
    return self.duration * (1 - self.elapsedPart)
end

Aura.createInstance = function(self)
    local aura = AuraInstance.new()
    aura.aura = self
    aura.appliedAt = utctime()
    return aura
end

Aura.isBeneficial = function(self)
    return self.auraType == AuraType.Buff
end

local QueryHandler = {
    RemoveThisAura = function(dispelMode)
        return function(self, unit)
            use"Spell".RemoveAura(unit, self.aura, dispelMode)
        end
    end
}


local logicalIncrement = 0
AuraInstance.new = Constructor(AuraInstance, {})
Aura.new = Constructor(Aura, {
    effectType = AuraDispelType.None, --Default effect type is none.
}, function(self)
    --Automatically assign id to have a common reference point sides
    logicalIncrement = logicalIncrement + 1
    self.id = logicalIncrement
end)

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
    override = AuraOverrideBehavior.ClearOldApplyNew,
})

Auras.PyroblastDot = Aura.new()
Auras.PyroblastDot:assign({
    name = "Pyroblast",
    tooltip = function(sheet)
        local str = "%s Fire damage inflicted every %ssec."
        return str
    end,
    icon = "rbxassetid://1337",
    onTick = schoolDot(Schools.Fire),
    effectType = AuraDispelType.Magic,
    auraType = AuraType.Debuff,
    decayType = AuraDecayType.Timed,
    affectedByCauserHaste = true,
    --baseTicks = 8,
    override = AuraOverrideBehavior.Pandemic,
})

Auras.ArcaneIntellect = Aura.new()
Auras.ArcaneIntellect:assign({
    name = "Arcane Intellect",
    tooltip = function(sheet)
        local str = "Intellect increased by %s%%."
        return str
    end,
    icon = "rbxassetid://1337",
    statMod = {
        intellect = 0.05,
    },
    effectType = AuraDispelType.Magic,
    auraType = AuraType.Buff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.ClearOldApplyNew,
})

Auras.Dummy = Aura.new()
Auras.Dummy:assign({
    name = "",
    tooltip = function(sheet)
        local str = ""
        return str
    end,
    icon = "rbxassetid://1337",
    effectType = AuraDispelType.None,
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
    },
    effectType = AuraDispelType.Magic,
    auraType = AuraType.Debuff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.Pandemic,
})

Auras.HeatingUp = Aura.new()
Auras.HeatingUp:assign({
    name = "Heating Up",
    tooltip = function(sheet)
        local str = "This unit has scored a spell critical and will gain Hot Streak if another follows."
        return str
    end,
    icon = "rbxassetid://1337",
    effectType = AuraDispelType.None,
    auraType = AuraType.InternalBuff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.Ignore, --Handled by Spellbook
})

Auras.HotStreak = Aura.new()
Auras.HotStreak:assign({
    name = "Hot Streak!",
    tooltip = function(sheet)
        local str = "Scored two spell criticals in a row and has empowered their next Pyroblast or Flamestrike."
        return str
    end,
    icon = "rbxassetid://1337",
    modCastType = {
        Pyroblast = CastType.Instant,
        Flamestrike = CastType.Instant,
    },
    onQuery = QueryHandler.RemoveThisAura(DispelMode.All),
    effectType = AuraDispelType.None,
    auraType = AuraType.InternalBuff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.Ignore, --Handled by Spellbook
})

Auras.BearForm = Aura.new()
Auras.BearForm:assign({
    name = "Bear Form",
    tooltip = function(sheet)
        local str = "Shapeshifted into a bear."
        str = str .. Linebreak .. "Armor increased by %s. Stamina increased by %s."
        return str
    end,
    icon = "rbxassetid://1337",
    statMod = {
        armor = 2.2,
        stamina = 0.25,
    },
    effectType = AuraDispelType.None,
    auraType = AuraType.InternalBuff,
    decayType = AuraDecayType.None,
    override = AuraOverrideBehavior.DropThisApplication,
})

Auras.Corruption = Aura.new()
Auras.Corruption:assign({
    name = "Corruption",
    tooltip = function(sheet)
        local str = "Suffering %s Shadow damage every %s."
        return str
    end,
    onTick = schoolDot(Schools.Shadow),
    icon = "rbxassetid://1337",
    effectType = AuraDispelType.Magic,
    auraType = AuraType.Debuff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.Pandemic,
    affectedByCauserHaste = true,
})

Auras.Kicked = Aura.new()
Auras.Kicked:assign({
    name = "Kicked",
    tooltip = function(sheet)
        local str = "This unit has been kicked and cannot be healed."
        return str
    end,
    icon = "rbxassetid://1337",
    effectType = AuraDispelType.None,
    auraType = AuraType.Hidden,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.DiminishingReturns,
})

return Aura