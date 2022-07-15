setfenv(1, require(script.Parent.Global))

local Aura = use"Object".inherit"Aura"
local AuraInstance = use"Object".inherit"AuraInstance"

local Linebreak = "\n"

local function auraDummy(spell, castingUnit, spellTarget, spellLocation)

end

local function schoolDotWithLifesteal(school)
    return function(aura, deltaTime, owner, tickStrength)
        local damage = (aura.aura.damagePerSecond(aura.causer, aura.causer.charsheet, aura)) * tickStrength
        local result = use"Spell".SchoolDamage(aura.spellSource, aura.causer, owner, damage, school, 1)
        if result.finalDamage and result.finalDamage > 0 then
            aura.causer.charsheet.spellbook:onDealDamage(aura.causer, owner, result.finalDamage, school, aura)
            use"Spell".SchoolHeal(
                aura.spellSource,
                aura.causer,
                aura.causer,
                aura.aura.lifesteal(
                    aura.causer,
                    aura.causer.charsheet,aura,
                    result
                ),
                school,
                1)
        end
    end
end

local function schoolDot(school)
    return function(aura, deltaTime, owner, tickStrength)
        local damage = (aura.aura.damagePerSecond(aura.causer, aura.causer.charsheet, aura)) * tickStrength
        local result = use"Spell".SchoolDamage(aura.spellSource, aura.causer, owner, damage, school, 1)

        if result.finalDamage and result.finalDamage > 0 then
            aura.causer.charsheet.spellbook:onDealDamage(aura.causer, owner, result.finalDamage, school, aura)
        end
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
        hasted = 1 + self.causer.charsheet:haste(self.causer)
    end

    if self.elapsedPart >= 1 then
        self.invalidate = true
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
        local elapsed = self.elapsedPart
        if elapsed >= nextLogicalTick then
            repeat --Multi-ticks for when haste overtakes heartbeat tick rate
                self.trulyElapsedPart = elapsed
                self.remainingTicks = self.remainingTicks - 1
                self.aura.onTick(self, deltaTime, owner, partialTick)
                nextLogicalTick = (1 + (ticks - self.remainingTicks)) / ticks
            until elapsed < nextLogicalTick
        end
    end

    self.elapsedPart = self.elapsedPart + (deltaTime / self.duration) * hasted
end

AuraInstance.remainingTime = function(self)
    if not self.duration then --We assume unset duration means the aura is permanent
        return math.huge
    end
    --The remaining time can only be approximated because changing haste mid-aura will change the time
    local hasteMod = 1
    if self.aura.affectedByCauserHaste
    and self.causer
    and self.causer.charsheet
    and self.causer.charsheet.haste then
        hasteMod = 1 + self.causer.charsheet:haste(self.causer)
    end

    return (self.duration * (1 - self.elapsedPart)) --This much base duration left (no haste)
            / hasteMod                              --Adjust for haste
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
            use"Spell".RemoveAura(unit, self.aura, dispelMode, nil, nil, nil, self.causer)
        end
    end
}


local logicalIncrement = 0
AuraInstance.new = Constructor(AuraInstance, {
    elapsedPart = 0,
    trulyElapsedPart = 0,
    duration = math.huge,
    aura = nil,
    causer = nil,
    spellSource = nil,
})
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
    damagePerSecond = function(caster, sheet)
        return (1.1 / 18) * sheet:spellPower(caster)
    end
})

Auras.Agony = Aura.new()
Auras.Agony:assign({
    name = "Agony",
    tooltip = function(sheet)
        local str = "Suffering %s Shadow damage every %s."
        return str
    end,
    onTick = function(aura, deltaTime, owner, tickStrength)
        local maxstacks = 12
        if aura.causer.charsheet.spellbook:hasSpell(Spells.WritheInAgony) then
            --Writhe in Agony talent
            maxstacks = 18
        end
        if tickStrength >= 1 and aura.stacks < maxstacks then
            --Ramp up damage
            aura.stacks = aura.stacks + 1
        end
        --TODO: Just make one DoT function for each school
        schoolDot(Schools.Shadow)(aura, deltaTime, owner, tickStrength)
    end,
    icon = "rbxassetid://1337",
    effectType = AuraDispelType.Curse,
    auraType = AuraType.Debuff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.Pandemic,
    affectedByCauserHaste = true,
    damagePerSecond = function(caster, sheet, auraInstance)
        return (0.2 / 18) * auraInstance.stacks * sheet:spellPower(caster)
    end
})

Auras.DrainLife = Aura.new()
Auras.DrainLife:assign({
    name = "Drain Life",
    tooltip = function(sheet)
        local str = "Suffering %s Shadow damage every %s. Some of the damage is transferred as healing to the caster."
        return str
    end,
    onTick = schoolDotWithLifesteal(Schools.Shadow),
    icon = "rbxassetid://1337",
    effectType = AuraDispelType.None,
    auraType = AuraType.Debuff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.ClearOldApplyNew,
    affectedByCauserHaste = true,
    damagePerSecond = function(caster, sheet, auraInstance)
        return (3/6) * sheet:spellPower(caster)
    end,
    lifesteal = function(caster, sheet, auraInstance, result)
        return result.finalDamage * 0.5
    end
})

Auras.Kicked = Aura.new()
Auras.Kicked:assign({
    name = "Kicked",
    tooltip = function(sheet)
        local str = "School spell cast interrupted."
        return str
    end,
    icon = "rbxassetid://1337",
    effectType = AuraDispelType.None,
    auraType = AuraType.Hidden,
    decayType = AuraDecayType.Timed,
    drGroup = DRGroup.Kick,
    override = AuraOverrideBehavior.DiminishingReturns,
})

Auras.Vicious = Aura.new()
Auras.Vicious:assign({
    name = "Vicious",
    tooltip = function(sheet)
        local str = "Haste increased by %s%%."
        return str
    end,
    icon = "rbxassetid://1337",
    statMod = {
        haste = 0.01,
    },
    effectType = AuraDispelType.None,
    auraType = AuraType.Hidden,
    decayType = AuraDecayType.None,
    override = AuraOverrideBehavior.Ignore,
})

local generalArmorProf = {
    name = "Armor Proficiency",
    tooltip = function(sheet)
        local str = "Primary stats increased by %s."
        return str
    end,
    icon = "rbxassetid://1337",
    statMod = {
        strength = 0.05,
        agility = 0.05,
        intellect = 0.05,
    },
    effectType = AuraDispelType.None,
    auraType = AuraType.Hidden,
    decayType = AuraDecayType.None,
    override = AuraOverrideBehavior.ClearOldApplyNew,
}

Auras.WarriorArmorProficiency = Aura.new()
Auras.WarriorArmorProficiency:assign(generalArmorProf)
Auras.MageArmorProficiency = Aura.new()
Auras.MageArmorProficiency:assign(generalArmorProf)
Auras.RogueArmorProficiency = Aura.new()
Auras.RogueArmorProficiency:assign(generalArmorProf)
Auras.PaladinArmorProficiency = Aura.new()
Auras.PaladinArmorProficiency:assign(generalArmorProf)
Auras.HunterArmorProficiency = Aura.new()
Auras.HunterArmorProficiency:assign(generalArmorProf)
Auras.DruidArmorProficiency = Aura.new()
Auras.DruidArmorProficiency:assign(generalArmorProf)
Auras.WarlockArmorProficiency = Aura.new()
Auras.WarlockArmorProficiency:assign(generalArmorProf)


Auras.Bloodlust = Aura.new()
Auras.Bloodlust:assign({
    name = "Bloodlust",
    tooltip = function(sheet)
        local str = "Haste increased by %s%%."
        return str
    end,
    icon = "rbxassetid://1337",
    statMod = {
        haste = 0.3,
    },
    effectType = AuraDispelType.None,
    auraType = AuraType.Buff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.ClearOldApplyNew,
})

Auras.Exhaustion = Aura.new()
Auras.Exhaustion:assign({
    name = "Exhaustion",
    tooltip = function(sheet)
        local str = "Cannot benefit from Bloodlust."
        return str
    end,
    icon = "rbxassetid://1337",
    effectType = AuraDispelType.None,
    auraType = AuraType.Debuff,
    decayType = AuraDecayType.Timed,
    override = AuraOverrideBehavior.ClearOldApplyNew,
})

return Aura