local ReplicatedStorage = game:GetService("ReplicatedStorage")
setfenv(1, require(script.Parent.Global))

local Charsheet = use"Object".inherit"Charsheet"
local Charclass = require(script.Parent.Charclass)

--Stat def for unit type (paper doll)

Charsheet.new = Constructor(Charsheet, {
    level = 1,

    class = Classes.Warrior,
    race = Races.Werebeast,
    spec = Specs.Protection,

    equipment = use"Equipment".new(),
})

Charsheet.isTank = function(self)
    if self.spec == Specs.Guardian then
        --TODO return isBear
        return true
    end
    return ({
        [Specs.Protection] = true,
        [Specs.Crusader] = true,
    })[self.spec or -1] or false
end

Charsheet.isStrengthSpec = function(self)
    return ({
        [Specs.Protection] = true,
        [Specs.Fury] = true,
        [Specs.Crusader] = true,
        [Specs.Guardian] = true,
    })[self.spec or -1] or false
end

Charsheet.isAgilitySpec = function(self)
    return ({
        [Specs.Marksman] = true,
        [Specs.Survival] = true,
        [Specs.Assassin] = true,
        [Specs.Combat] = true,
        [Specs.Feral] = true,
    })[self.spec or -1] or false
end

for _, primStat in ipairs({"strength", "stamina", "agility", "intellect"}) do
    Charsheet[primStat] = function(self)
        local classBase = math.round(BasePrimaryStat(primStat, self.level, self.class, self.race))
        local gearBase = self.equipment:aggregate(primStat)
        local auraMod = 1
        return (classBase + gearBase) * auraMod
    end
end

Charsheet.attackPower = function(self)
    local value = math.round(self.equipment:aggregate("attackPower"))
    if self:isStrengthSpec() then
        value = value + self:strength()
    end
    if self:isAgilitySpec() then
        value = value + self:agility()
    end
    if self:isTank() then
        value = value * (1 + self:mastery())
    end
    if self.spec == Specs.Restoration or self.spec == Specs.Divination then
        local spAuraMod = 1
        value = (math.round(self.equipment:aggregate("spellPower")) + self:intellect()) * spAuraMod * 1.04
    end
    local apAuraMod = 1
    return value * apAuraMod
end

Charsheet.spellPower = function(self)
    local value = math.round(self.equipment:aggregate("attackPower")) + self:intellect()
    if self.spec == Specs.Protection then
        value = self:abilityDamage(true) * 1.01
    end
    if self.spec == Specs.Feral or self.spec == Specs.Guardian then
        value = self:abilityDamage(true) * 0.96
    end
    local spAuraMod = 1
    return value * spAuraMod
end

Charsheet.abilityDamage = function(self, isMainHand)
    local value
    if isMainHand then
        for k, v in pairs(self.equipment) do
            print(k, v)
        end
        value = math.round(self:totalMainHandDamage() / self.equipment[Slots.MainHand]:weaponSpeed())
    else
        value = math.round(self:totalOffHandDamage() / self.equipment[Slots.OffHand]:weaponSpeed())
    end
    value = value * 6
    if self:isTank() then
        value = value * (1 + self:mastery())
    end
    local adAuraMod = 1
    value = value * adAuraMod + self:attackPower()
    if not isMainHand then
        value = value * 0.5
    end
    return value
end

Charsheet.totalMainHandDamage = function(self)
    return self.equipment[Slots.MainHand].weaponDamage
end

Charsheet.totalOffHandDamage = function(self)
    return self.equipment[Slots.OffHand].weaponDamage
end

return Charsheet