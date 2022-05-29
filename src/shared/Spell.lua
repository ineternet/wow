setfenv(1, require(script.Parent.Global))

local Spell = use"Object".inherit"Spell"

local function spellDummy(spell, castingUnit, spellTarget, spellLocation)
    return function() end
end

local function schoolDamage(args)
    return function(spell, castingUnit, spellTarget, _)
        local damage = args.damage(castingUnit.charsheet)
        local school = args.school
        local crit = args.forceCrit or castingUnit:procCrit(spell)
        local isPvp = spellTarget and spellTarget:is"PlayerUnit"
        if isPvp then
            damage = damage * (args.pvp or 1)
        end
        if crit then
            local critm = castingUnit.charsheet:critMultiplier(isPvp)
            damage = damage * (critm)
        end
        spellTarget:takeDamage(damage, school)
    end
end

local function schoolHeal(args)
    return function(spell, castingUnit, spellTarget, _)

    end
end

local function area(args)
    return function(spell, castingUnit, _, spellLocation)
        
    end
end

local function applyAura(args)
    return function(spell, castingUnit, spellTarget, _)
        
    end
end

local function projectile(args)
    return function(spell, castingUnit, spellTarget, spellLocation)
        print("Blocking for 1 second to simulate projectile travel time.")
        task.wait(1)
    end
end

Spell.new = Constructor(Spell, {

})

Spells.FireBlast = Spell.new()
Spells.FireBlast:assign({
    name = "Fire Blast",
    tooltip = function(sheet)
        local str = "Blast an enemy for %s Fire damage."
        if sheet.spec == Specs.Fire then
            str = str .. "\n\n" .. "Castable while casting other spells."
        end
        if sheet.spec == Specs.Fire and sheet.level >= 18 then
            str = str .. "\n\n" .. "Always critically strikes."
        end
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.01,

    recharge = 12,
    charges = 1,
    cooldown = 0.5,
    gcd = GCD.None,

    castType = CastType.Instant,
    targetType = TargetType.Enemy,
    range = Range.Long,

    school = Schools.Fire,
    effects = {
        schoolDamage {
            school = Schools.Fire,
            damage = function(sheet)
                return 1 * sheet:spellPower()
            end,
            forceCrit = true,
            pvp = 0.8
        },
    },

})

Spells.Fireball = Spell.new()
Spells.Fireball:assign({
    name = "Fireball",
    tooltip = function(sheet)
        local str = "Hurl a ball of flame at an enemy, dealing %s Fire damage."
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.02,

    cooldown = 0,
    gcd = GCD.Standard,

    castType = CastType.Cast,
    castTime = 3,
    targetType = TargetType.Enemy,
    range = Range.Long,

    school = Schools.Fire,
    effects = {
        projectile {
            arriveWithin = 0.5,
            type = Projectiles.Fireball,
            size = 1,
        },
        schoolDamage {
            school = Schools.Fire,
            damage = function(sheet)
                return 2 * sheet:spellPower()
            end
        },
    },

})

Spells.Pyroblast = Spell.new()
Spells.Pyroblast:assign({
    name = "Pyroblast",
    tooltip = function(sheet)
        local str = "Conjures an immense boulder of flame that deals %s Fire damage."
        if sheet.spec == Specs.Fire and sheet.level >= 54 then
            str = str .. "\n\n" .. "Additionally burns the target for %s Fire damage over %s seconds."
        end
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.02,

    cooldown = 0,
    gcd = GCD.Standard,

    castType = CastType.Cast,
    castTime = 4.5,
    targetType = TargetType.Enemy,
    range = Range.Long,

    school = Schools.Fire,
    --instantCastWhen = hasAura(Auras.HotStreak),
    effects = {
        projectile {
            arriveWithin = 0.3,
            type = Projectiles.Fireball,
            size = 2,
        },
        schoolDamage {
            school = Schools.Fire,
            damage = function(sheet)
                return 1.5 * sheet:spellPower()
            end,
        },
        applyAura {
            aura = Auras.PyroblastDot,
        },
    },

})

Spells.Flamestrike = Spell.new()
Spells.Flamestrike:assign({
    name = "Flamestrike",
    tooltip = function(sheet)
        local str = "Summon a pillar of flame that damages all enemies within %s yards for %s Fire damage, and additionally slows them by %s%% for %s seconds."
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.025,

    cooldown = 0,
    gcd = GCD.Standard,

    castType = CastType.Cast,
    castTime = 4,
    targetType = TargetType.Area,
    areaSize = 5,
    range = Range.Long,

    school = Schools.Fire,
    --instantCastWhen = hasAura(Auras.HotStreak),
    effects = {
        area {
            size = 5,
            targetType = TargetType.Enemy,
            effects = {
                schoolDamage {
                    school = Schools.Fire,
                    damage = function(sheet)
                        return 0.55 * sheet:spellPower()
                    end,
                },
                applyAura {
                    aura = Auras.FlamestrikeSlow,
                },
            },
        }
    },

})

Spells.MortalStrike = Spell.new()
Spells.MortalStrike:assign({
    name = "Mortal Strike",
    tooltip = function(sheet)
        local mwAura = Auras.MortalWounds
        local str = "A vicious strike that deals %s Physical damage and applies " .. mwAura.name .. " for %s seconds."
        str = str .. "\n\n" .. mwAura.name .. ": " .. mwAura.tooltip(sheet)
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Fury,
    resourceCost = 30,

    cooldown = 6,
    gcd = GCD.Standard,

    castType = CastType.Instant,
    targetType = TargetType.Enemy,
    range = Range.Combat,

    school = Schools.Physical,
    effects = {
        schoolDamage {
            school = Schools.Physical,
            damage = function(sheet)
                return 1.6 * sheet:attackPower()
            end,
            pvp = 0.76
        },
        applyAura {
            aura = Auras.MortalWounds,
            amount = 0.5,
            duration = 6,
        },
    },
})
--[[
Spells.WaterElemental = Spell.new()
Spells.WaterElemental:assign({
    name = "Water Elemental",
    tooltip = function(sheet)
        local str = "Summon a Water Elemental to fight for you."
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.01,

    cooldown = 0,
    gcd = GCD.Standard,

    castType = CastType.Cast,
    castTime = 2,
    targetType = TargetType.Self,

    school = Schools.Water,
    effects = {
        summon {
            unit = Units.WaterElemental,
            duration = 0,
        },
    },
})
]]

Spells.FlashOfLight = Spell.new()
Spells.FlashOfLight:assign({
    name = "Flash of Light",
    tooltip = function(sheet)
        local str = "A fast blessing that heals an ally for %s."
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.22,

    cooldown = 0,
    gcd = GCD.Standard,

    castType = CastType.Cast,
    castTime = 0.7,
    targetType = TargetType.Friendly,
    range = Range.Long,

    school = Schools.Holy,
    effects = {
        schoolHeal {
            school = Schools.Holy,
            amount = function(sheet)
                return 2 * sheet:spellPower()
            end
        },
    },
})

return Spell