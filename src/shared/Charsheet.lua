setfenv(1, require(script.Parent.Global))

local Charsheet = use"Object".inherit"Charsheet"

--Stat def for unit type (paper doll)

Charsheet.new = Constructor(Charsheet, {
    level = 1,

    class = Classes.Classless,
    race = Races.None,
    spec = Specs.None,

    equipment = use"Equipment".new,

    spellbook = use"Spellbook".new,
}, function(self)

end)

--Whether this unit can wield 1H main-hands in the off-hand slot.
Charsheet.canDualWield = function(self)
    return self.class == Classes.Warrior or self.class == Classes.Rogue
end

Charsheet.baseMana = function(self)
    local value = BaseMana[self.level]
    if self.class == Classes.Mage or self.class == Classes.Priest or self.class == Classes.Warlock then
        --Caster classes get more base mana.
        value = value * 5
    end
    return value
end

Charsheet.isTank = function(self, unit)
    if self.spec == Specs.Guardian then
        local isBear = unit:hasAura(Auras.BearForm)
        return isBear
    end
    return ({
        [Specs.Protection] = true,
        [Specs.Crusader] = true,
    })[self.spec or 0] or false
end

Charsheet.isStrengthSpec = function(self)
    return ({
        [Specs.Protection] = true,
        [Specs.Fury] = true,
        [Specs.Crusader] = true,
        [Specs.Guardian] = true,
    })[self.spec or 0] or false
end

Charsheet.isAgilitySpec = function(self)
    return ({
        [Specs.Marksman] = true,
        [Specs.Survival] = true,
        [Specs.Assassin] = true,
        [Specs.Combat] = true,
        [Specs.Feral] = true,
    })[self.spec or 0] or false
end

--Primary stats
for _, primStat in ipairs({"strength", "stamina", "agility", "intellect"}) do
    Charsheet[primStat] = function(self, unit)
        local classBase = math.round(BasePrimaryStat(primStat, self.level, self.class, self.race))
        local gearBase, gearMod = self.equipment:aggregate(primStat)
        local auraMod = unit:auraStatMod(primStat)
        return (classBase + gearBase) * gearMod * auraMod
    end
end

Charsheet.attackPower = function(self, unit)
    local gbase, gmod = self.equipment:aggregate("attackPower")
    local value = math.round(gbase * gmod)
    if self:isStrengthSpec() then
        value = value + self:strength(unit)
    end
    if self:isAgilitySpec() then
        value = value + self:agility(unit)
    end
    if self:isTank(unit) then
        value = value * (1 + self:mastery(unit))
    end
    if self.spec == Specs.Restoration or self.spec == Specs.Divination then
        value = self:spellPower(unit) * 1.04
    end
    local apAuraMod = unit:auraStatMod("attackPower")
    return value * apAuraMod
end

Charsheet.spellPower = function(self, unit)
    local gbase, gmod = self.equipment:aggregate("spellPower")
    local value = math.round(gbase * gmod) + self:intellect(unit)
    if self.spec == Specs.Crusader then
        value = self:abilityDamage(true) * 1.01
    end
    if self.spec == Specs.Feral or self.spec == Specs.Guardian then
        value = self:abilityDamage(true) * 0.96
    end
    local spAuraMod = unit:auraStatMod("spellPower")
    return value * spAuraMod
end

Charsheet.abilityDamage = function(self, unit, isMainHand)
    local value
    if isMainHand then
        value = math.round(self:totalMainHandDamage() / self.equipment.slots[Slots.MainHand]:flat("weaponSpeed"))
    else
        value = math.round(self:totalOffHandDamage() / self.equipment.slots[Slots.OffHand]:flat("weaponSpeed"))
    end
    value = value * 6
    if self:isTank() then
        value = value * (1 + self:mastery(unit))
    end
    local adAuraMod = unit:auraStatMod("abilityDamage")
    value = value * adAuraMod + self:attackPower(unit)
    if not isMainHand then
        value = value * 0.5
    end
    return value
end

--This is much simpler than the real calculation
local function diminish(x)
    if x > 1.2 then
        return diminish(1.2)
    end
    return x - x * (math.exp(0.1 * x) - 1)
end
Charsheet.diminishSecondaryStat = function(self, stat)
    local gbase, gmod = self.equipment:aggregate(stat)
    local rating = math.round(gbase * gmod)
    local pctStat = (rating / SecondaryRatingConversion[stat][self.level]) * 0.01
    return diminish(pctStat) * 100
end

--Secondary stats

Charsheet.mastery = function(self, unit)
    local mAuraFlat = unit:auraStatFlat("mastery")
    local value = (8 + mAuraFlat + self:diminishSecondaryStat("mastery")) / 100
    return value
end

Charsheet.versatility = function(self, unit)
    local vAuraFlat = unit:auraStatFlat("versatility")
    local value = (vAuraFlat + self:diminishSecondaryStat("versatility")) / 100
    return value
end

Charsheet.crit = function(self, unit)
    local cAuraFlat = unit:auraStatFlat("crit")
    local value = 0.05 + (cAuraFlat + self:diminishSecondaryStat("crit")) / 100
    return value
end

Charsheet.haste = function(self, unit)
    local hAuraMod = unit:auraStatMod("haste")
    local value = (1 + self:diminishSecondaryStat("haste") / 100) * hAuraMod - 1
    return value
end

--Simple tertiary stats

for _, tertStat in ipairs({"avoidance", "leech", "speed"}) do
    local mval = 0
    if tertStat == "avoidance" then
        mval = 0.2
    end
    Charsheet[tertStat] = function(self, unit)
        local aAuraMod = unit:auraStatFlat(tertStat)
        local gearBase, gearMod = self.equipment:aggregate(tertStat)
        local avd = gearBase * gearMod
        local value = aAuraMod + math.min(mval, math.round(avd) / SecondaryRatingConversion[tertStat][self.level] / 100)
        return value
    end
end

--Other

Charsheet.armor = function(self, unit)
    local aAuraFlat = unit:auraStatFlat("armor")
    local aAuraMod = unit:auraStatMod("armor")
    local baseArmor, modArmor = self.equipment:aggregate("armor")
    local base = math.round((baseArmor) + 2 * self:agility(unit))
    local value = (base * modArmor * aAuraMod) + aAuraFlat
    return value
end

--Percentage of physical damage mitigated by armor
Charsheet.physicalDR = function(self, unit, enemySheet)
    local armor = self:armor(unit)
    return (armor / (85 * enemySheet.level + armor + 400))
end

Charsheet.totalMainHandDamage = function(self)
    return self.equipment.slots[Slots.MainHand]:flat("weaponDamage")
end

Charsheet.totalOffHandDamage = function(self)
    return self.equipment.slots[Slots.OffHand]:flat("weaponDamage")
end

--Return GCD length in seconds, considering haste.
Charsheet.gcd = function(self, unit, gcdEnum)
    local haste = self:haste(unit)
    local gcd = GCDTimeout[gcdEnum]
    return gcd / (1 + haste)
end

--[[
    Calculate how much damage a unit will actually take from a given amount of damage.
    @param unit The unit this charsheet belongs to.
    @param causerSheet The sheet of the unit that caused the damage.
    @param damage The amount of damage to be taken.
    @param school Damage school
    @param isMassive Whether this damage is meant to deal a lot of damage - some mitigations are ignored.
    @return The amount of damage actually taken.
]]
Charsheet.mitigate = function(self, unit, causerSheet, damage, school, isMassive)
    if school == Schools.Physical then
        local dr = self:physicalDR(unit, causerSheet or { level = self.level })
        damage = damage * (1 - dr)
    end

    return damage
end

--How much damage a critical strike will do.
Charsheet.critMultiplier = function(self, isPvp)
    local val = 2
    if isPvp then
        val = 1.5
    end
    return val
end

Charsheet.healthRegen = function(self)
    return 0.01
end

Charsheet.manaRegen = function(self)
    return 0.02
end

Charsheet.energyRegen = function(self)
    return 0.3
end

Charsheet.focusRegen = function(self)
    return 0.2
end

--How many seconds before a unit that left combat will start regenerating with out-of-combat regeneration.
Charsheet.combatRegenDelay = function(self)
    return 5
end

return Charsheet
