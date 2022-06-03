setfenv(1, require(script.Parent.Global))

local Spell = use"Object".inherit"Spell"

local Linebreak = "\n\n"

local function spellDummy(spell, castingUnit, spellTarget, spellLocation)
    return function() end --If this function returns "true", following effects will NOT be applied.
end

Spell.SchoolDamage = function(castingUnit, spellTarget, damage, school, pvpModifier, forceCrit)
    local crit = forceCrit or castingUnit:procCrit(spell)
    local isPvp = spellTarget and spellTarget:is"PlayerUnit"
    if isPvp then
        damage = damage * (pvpModifier or 1)
    end
    if crit then
        local critm = castingUnit.charsheet:critMultiplier(isPvp)
        damage = damage * (critm)
    end
    spellTarget:takeDamage(damage, school)

    return {
        crit = crit,
        isPvp = isPvp,
        finalDamage = damage
    }
    
end

local function effectOnTargetModel(args)
    return function(_, _, spellTarget, _)
        args.effect(workspace.Dummy)
    end
end

local function schoolDamage(args)
    return function(spell, castingUnit, spellTarget, _)
        local damage = args.damage(castingUnit, castingUnit.charsheet)
        local school = args.school
        local result = Spell.SchoolDamage(castingUnit, spellTarget, damage, school, args.pvp, args.forceCrit)
    
        if result.crit then
            castingUnit.spellbook:onSpellCritical(castingUnit, spell, spellTarget, _)
        end
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
        print("Applying aura")
        local auraInstance = args.aura:createInstance()
        for k, v in pairs(args.auraData or {}) do
            auraInstance[k] = v
        end
        auraInstance.causer = ref(castingUnit)
        print("Applying aura to", spellTarget, "for", args.auraData.duration)
        --table.insert(spellTarget.auras, auraInstance)
        replicatedInsert(spellTarget.auras, auraInstance)
        print(spellTarget.auras.noproxy)
    end
end

Spell.RemoveAura = function(fromUnit, aura, dispelMode, specificAmount)
    if not dispelMode then
        dispelMode = DispelMode.All
    end
    if dispelMode == DispelMode.None then
        return
    end

    print("Attempting to remove aura", aura, "from", fromUnit)

    local markedForRemoval = {}
    local amountMarked = 0
    local latestTime = 0
    local latestAura = nil
    for i, auraInstance in ipairs(fromUnit.auras.noproxy) do
        if auraInstance.aura.id == aura.id then
            if dispelMode ~= DispelMode.Latest then
                markedForRemoval[i] = true
            else
                if auraInstance.appliedAt > latestTime then
                    latestTime = auraInstance.appliedAt
                    latestAura = i
                end
            end
            if dispelMode == DispelMode.First then
                break
            elseif dispelMode == DispelMode.All then
                --Do nothing
            elseif dispelMode == DispelMode.SpecificAmount then
                if #markedForRemoval >= specificAmount then
                    break
                end
            end
        end
    end
    if latestAura then
        markedForRemoval[latestAura] = true
    end

    print("Marked for removal:", markedForRemoval)

    local shift = 0
    local fTop = #fromUnit.auras.noproxy
    for i = 1, fTop+1 do
        if markedForRemoval[i-1] then
            shift = shift + 1
        end
        if shift > 0 then
            fromUnit.auras[i-shift] = fromUnit.auras[i]
        end
    end
    for i = fTop-shift+1, fTop do
        fromUnit.auras[i] = nil
    end --TODO: May need to finalize each aura to clear connections
end

local function removeAura(args)
    return function(spell, castingUnit, spellTarget, _)
        Spell.RemoveAura(spellTarget, args.aura, args.dispelMode)
    end
end



local function projectile(args)
    return function(spell, castingUnit, spellTarget, spellLocation)
        print("Blocking for 1 second to simulate projectile travel time.")
        local fb = game.Lighting.Part:Clone()
        local start = game.Players:GetPlayers()[1].Character.HumanoidRootPart.Position
        local goal = workspace.Dummy.Torso.Position
        fb.Parent = workspace
        fb.Anchored = false
        fb.CFrame = CFrame.new(start, goal)
        fb:SetNetworkOwner(game.Players:GetPlayers()[1])
        local spd = 0.5
        --fb.AlignOrientation
        fb.Velocity = (goal - start) / spd
        task.wait(spd)
        local fn = args.onArriveWorldModel
        if fn then
            fn(workspace.Dummy)
        end
        fb.Anchored = true
        fb.Transparency = 1
        task.delay(2, function()
            fb:Destroy()
        end)
    end
end

local function multi(args) --Wrap multiple effects in a single function, preserving order
    return function(...)
        print("Multicasting with args", ...)
        for i, v in ipairs(args) do
            v(...)
        end
    end
end

local function ifHasAura(aura)
    return function(args)
        return function(spell, castingUnit, spellTarget, spellLocation)
            local effect = args.effect
            local compoundReturn = false

            --print(castingUnit.auras.noproxy)
            if castingUnit:hasAura(aura) then
                print("Has aura")
                compoundReturn = args.dropFollowingEffects
                compoundReturn = effect(spell, castingUnit, spellTarget, spellLocation) or compoundReturn
            end

            return compoundReturn
        end
    end
end

local function onEach(args)
    return function(spell, castingUnit, spellTarget, spellLocation)
        local collector = args.collector
        local effect = args.effect
        local compoundReturn = args.dropFollowingEffects

        local targets = collector(spell, castingUnit, spellTarget, spellLocation)
        for _, pt in ipairs(targets) do
            for order, v in ipairs(effect) do
                compoundReturn = v(spell, castingUnit, pt, spellLocation) or compoundReturn
            end
        end

        return compoundReturn
    end
end

local collectors = {
    SamePartyElseTargetOnly = function(_, castingUnit, spellTarget, _)
        assertObj(spellTarget)
        if not castingUnit or not spellTarget:is"PlayerUnit" or not castingUnit.is or not castingUnit:is"PlayerUnit" then
            --Automatically fail if target is not a player or if caster is not a player (can not be in parties)
            --Continue to end of function
        elseif castingUnit.is and castingUnit:is("PlayerUnit") then
            if castingUnit.party and spellTarget.party and castingUnit.party == spellTarget.party then
                return castingUnit.party.units.noproxy
            end
        end
        return {spellTarget}
    end
}

local logicalIncrement = 0
Spell.new = Constructor(Spell, {
    icon = "rbxassetid://1337",

    cooldown = 0,
    gcd = GCD.None,

    castType = CastType.Instant,
    targetType = TargetType.Self,
    range = Range.Unlimited,

    school = Schools.Physical,
}, function(self)
    --Automatically assign id to have a common reference point sides
    logicalIncrement = logicalIncrement + 1
    self.id = logicalIncrement
end)

Spells.ApplyDummyAura = Spell.new()
Spells.ApplyDummyAura:assign({
    name = "Apply Dummy Aura",
    description = "Applies a dummy aura to the target.",
    icon = "rbxassetid://1337",
    effects = {
        applyAura {
            aura = Auras.Dummy,
            auraData = {
                duration = 100,
            },
        },
    },
})

Spells.FireBlast = Spell.new()
Spells.FireBlast:assign({
    name = "Fire Blast",
    tooltip = function(sheet)
        local str = "Blast an enemy for %s Fire damage."
        if sheet.spec == Specs.Fire then
            str = str .. Linebreak .. "Castable while casting other spells."
        end
        if sheet.spec == Specs.Fire and sheet.level >= 18 then
            str = str .. Linebreak .. "Always critically strikes."
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
        effectOnTargetModel {
            effect = Effects.Combust,
        },
        schoolDamage {
            school = Schools.Fire,
            damage = function(caster, sheet)
                return 0.4 * sheet:spellPower(caster)
            end,
            forceCrit = true,
            pvp = 0.8
        },
    },

    castableWhileCasting = function(unit)
        return unit.charsheet.spec == Specs.Fire
    end,
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

    castType = CastType.Casting,
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
            damage = function(caster, sheet)
                return 2 * sheet:spellPower(caster)
            end
        },
    },

})

Spells.HotStreak = Spell.new()
Spells.HotStreak:assign({
    name = "Hot Streak",
    tooltip = function(sheet)
        local str = "Whenever you land two critical strikes in a row, your next Pyroblast or Flamestrike will be instant cast."
        return str
    end,
    icon = "rbxassetid://1337",

    castType = CastType.Passive,

    school = Schools.Physical,
    effects = {
        ifHasAura(Auras.HeatingUp) { --If already Heating Up, apply Hot Streak
            dropFollowingEffects = true,
            effect = multi {
                removeAura { --Remove Heating Up
                    aura = Auras.HeatingUp,
                    dispelMode = DispelMode.All,
                },
                applyAura {
                    aura = Auras.HotStreak,
                    auraData = {
                        duration = 10,
                    },
                },
            }
        },
        applyAura { --If not Heating Up, apply Heating Up
            aura = Auras.HeatingUp,
            auraData = {
                duration = 10,
            },
        },
    },

})

Spells.Pyroblast = Spell.new()
Spells.Pyroblast:assign({
    name = "Pyroblast",
    tooltip = function(sheet)
        local str = "Conjures an immense boulder of flame that deals %s Fire damage."
        if sheet.spec == Specs.Fire and sheet.level >= 54 then
            str = str .. Linebreak .. "Additionally burns the target for %s Fire damage over %s seconds."
        end
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.02,

    cooldown = 0,
    gcd = GCD.Standard,

    castType = CastType.Casting,
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
            onArriveWorldModel = Effects.Combust
        },
        schoolDamage {
            school = Schools.Fire,
            damage = function(caster, sheet)
                return 1.5 * sheet:spellPower(caster)
            end,
        },
        applyAura {
            aura = Auras.PyroblastDot,
            auraData = {
                duration = 6,
                damage = function(caster, sheet)
                    return 0.5 * sheet:spellPower(caster)
                end,
            },
        },
    },

})

Spells.ArcaneIntellect = Spell.new()
Spells.ArcaneIntellect:assign({
    name = "Arcane Intellect",
    tooltip = function(sheet)
        local str = "Increases the Intellect of an ally by %s%% for 60 minutes."
        str = str .. "\n\n" .. "If cast on a party member, everyone in the party gains the same bonus."
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.04,

    cooldown = 0,
    gcd = GCD.Default,

    castType = CastType.Instant,
    targetType = TargetType.Friendly,
    range = Range.Long,

    school = Schools.Arcane,
    effects = {
        onEach {
            collector = collectors.SamePartyElseTargetOnly,
            effect = {
                effectOnTargetModel {
                    effect = Effects.ArcaneIntellect,
                },
                applyAura {
                    aura = Auras.ArcaneIntellect,
                    auraData = {
                        duration = 60 * 60,
                    },
                },
            },
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

    castType = CastType.Casting,
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
                    damage = function(caster, sheet)
                        return 0.55 * sheet:spellPower(caster)
                    end,
                },
                applyAura {
                    aura = Auras.FlamestrikeSlow,
                    auraData = {
                        duration = 3,
                    },
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
        str = str .. Linebreak .. mwAura.name .. ": " .. mwAura.tooltip(sheet)
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
            damage = function(caster, sheet)
                return 1.6 * sheet:attackPower(caster)
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

    castType = CastType.Casting,
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

    castType = CastType.Casting,
    castTime = 0.7,
    targetType = TargetType.Friendly,
    range = Range.Long,

    school = Schools.Holy,
    effects = {
        schoolHeal {
            school = Schools.Holy,
            amount = function(caster, sheet)
                return 2 * sheet:spellPower(caster)
            end
        },
    },
})


return Spell