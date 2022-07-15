setfenv(1, require(script.Parent.Global))

local Spell = use"Object".inherit"Spell"

local Linebreak = "\n\n"

local function spellDummy(spell, castingUnit, spellTarget, spellLocation)
    return function() end --If this function returns "true", following effects will NOT be applied.
end

Spell.SchoolDamage = function(spell, castingUnit, spellTarget, damage, school, pvpModifier, forceCrit)
    local crit = forceCrit or castingUnit:procCrit(spell)
    local isPvp = spellTarget and spellTarget:is"PlayerUnit" and castingUnit and castingUnit:is"PlayerUnit"
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

Spell.SchoolHeal = function(spell, castingUnit, spellTarget, damage, school, pvpModifier, forceCrit)
    local crit = forceCrit or castingUnit:procCrit(spell)
    --TODO: PVP check has to depend on PVP status, not on the spell target
    local isPvp = false
    --local isPvp = spellTarget and spellTarget:is"PlayerUnit" and castingUnit and castingUnit:is"PlayerUnit"
    if isPvp then
        damage = damage * (pvpModifier or 1)
    end
    if crit then
        local critm = castingUnit.charsheet:critMultiplier(isPvp)
        damage = damage * (critm)
    end
    spellTarget:receiveHeal(damage, school)

    return {
        crit = crit,
        isPvp = isPvp,
        finalDamage = damage
    }
end

local function effectOnTargetModel(args)
    return function(_, _, spellTarget, _)
        if _VERSION ~= "Luau" then
            return
        end
        args.effect(workspace.Dummy)
    end
end

local function schoolDamage(args)
    return function(spell, castingUnit, spellTarget, _)
        local damage = args.damage(castingUnit, castingUnit.charsheet)
        local school = args.school
        local result = Spell.SchoolDamage(spell, castingUnit, spellTarget, damage, school, args.pvp, args.forceCrit)
    
        if result.crit then
            castingUnit.charsheet.spellbook:onSpellCritical(castingUnit, spell, spellTarget, _)
        end
        if result.finalDamage and result.finalDamage > 0 then
            castingUnit.charsheet.spellbook:onDealDamage(castingUnit, spellTarget, result.finalDamage, school, spell)
        end
    end
end

local function schoolHeal(args)
    return function(spell, castingUnit, spellTarget, _)
        local damage = args.damage(castingUnit, castingUnit.charsheet)
        local school = args.school
        local result = Spell.SchoolHeal(spell, castingUnit, spellTarget, damage, school, args.pvp, args.forceCrit)
        --[[if result.crit then
            castingUnit.charsheet.spellbook:onSpellCritical(castingUnit, spell, spellTarget, _)
        end
        if result.finalDamage and result.finalDamage > 0 then
            castingUnit.charsheet.spellbook:onDealHealing(castingUnit, spellTarget, result.finalDamage, school, spell)
        end]]
    end
end

local function area(args)
    return function(spell, castingUnit, _, spellLocation)
        
    end
end

Spell.ApplyAura = function(spell, toUnit, aura, causer, auraData)
    auraData = auraData or {duration = math.huge}
    local overrideBehavior = auraData.override or aura.override or AuraOverrideBehavior.Ignore

    local overrides = {
        sourceSpell = spell,
        doNotCreateNewAura = false,
        updateOldAura = false,
        oldAura = nil,
        duration = nil
    }
    if overrideBehavior == AuraOverrideBehavior.Ignore then
        --Do nothing
    elseif overrideBehavior == AuraOverrideBehavior.ClearOldApplyNew then
        Spell.RemoveAura(toUnit, aura, DispelMode.All, nil, nil, nil, causer)
    elseif overrideBehavior == AuraOverrideBehavior.UpdateOldDuration then
        overrides.oldAura = toUnit:findFirstAura(aura, causer)
        overrides.doNotCreateNewAura = true
        if overrides.oldAura then
            overrides.updateOldAura = true
        end
    elseif overrideBehavior == AuraOverrideBehavior.Pandemic then
        local old = toUnit:findFirstAura(aura, causer)
        local pandemicDuration = math.clamp(
            old and old:remainingTime() or 0, --If there is an old aura, apply its remaining time
            0,
            auraData.duration * 0.3 --up to 30% of the base duration.
        )
        if old then
            overrides.doNotCreateNewAura = true
            overrides.updateOldAura = true
            overrides.oldAura = old
            overrides.stacks = old.stacks or nil
        end
        auraData.elapsedPart = old and (old.elapsedPart - old.trulyElapsedPart) or 0
        auraData.duration = auraData.duration + pandemicDuration
        --if old then
        --    Spell.RemoveAuraInstance(toUnit, old)
        --end
    elseif overrideBehavior == AuraOverrideBehavior.Stack or overrideBehavior == AuraOverrideBehavior.StackDontUpdate then
        overrides.doNotCreateNewAura = true
        overrides.updateOldAura = true
        overrides.oldAura = toUnit:findFirstAura(aura)
        auraData.stacks = (auraData.stacks or 0) + overrides.oldAura.stacks
    elseif overrideBehavior == AuraOverrideBehavior.DropThisApplication then
        if toUnit:hasAura(aura, causer) then
            return
        end
    elseif overrideBehavior == AuraOverrideBehavior.DiminishingReturns then
        --Same as Ignore. TODO
    elseif overrideBehavior == AuraOverrideBehavior.CreateStacksOrPandemic then
        local old = toUnit:findFirstAura(aura, causer)
        local pandemicDuration = math.clamp(
            old and old:remainingTime() or 0, --If there is an old aura, apply its remaining time
            0,
            auraData.duration * 0.3 --up to 30% of the base duration.
        )
        overrides.duration = auraData.duration + pandemicDuration
        if old then
            Spell.RemoveAuraInstance(toUnit, old)
        end
    end

    local auraInstance
    if not overrides.doNotCreateNewAura then
        auraInstance = aura:createInstance()
    end

    for _, auraInstance in pairs({
        overrides.doNotCreateNewAura and nil or auraInstance,
        overrides.updateOldAura and overrides.oldAura or nil,
    }) do
        for k, v in pairs(auraData or {}) do
            if overrides[k] then
                auraInstance[k] = overrides[k]
            else
                auraInstance[k] = resolveNumFn(v, causer.charsheet)
            end
        end
        if causer then
            auraInstance.causer = ref(causer)
        end
    end

    if auraInstance then
        replicatedInsert(toUnit.auras, auraInstance)
        if causer then
            replicatedInsert(causer.castAuras, auraInstance)
        end
        return auraInstance
    end
end

local function applyAura(args)
    return function(spell, castingUnit, spellTarget, _)
        Spell.ApplyAura(spell, spellTarget, args.aura, castingUnit, args.auraData)
    end
end

local function channelAura(args) --TODO
    return function(spell, castingUnit, spellTarget, _)
        Spell.ApplyAura(spell, spellTarget, args.aura, castingUnit, args.auraData)
    end
end

Spell.RemoveAura = function(fromUnit, auraOrArg, dispelMode, specificAmount, removalMode, onlyRemoveThisType, onlyCausedByThisUnit)
    if not dispelMode then
        dispelMode = DispelMode.All
    end
    if dispelMode == DispelMode.None then
        return
    end

    local markedForRemoval = {}
    local amountMarked = 0
    local latestTime = 0
    local latestAura = nil
    for i, auraInstance in ipairs(fromUnit.auras.noproxy) do
        if (((not removalMode or removalMode == AuraRemovalMode.ById) and auraInstance.aura.id == auraOrArg.id)
        or (removalMode == AuraRemovalMode.ByDispelType and auraInstance.aura.effectType == auraOrArg and auraOrArg ~= nil)
        or (removalMode == AuraRemovalMode.ByAura and auraInstance.aura:ReferenceEquals(auraOrArg))) --Avoid using this mode, it may not work across sides
        and (not onlyRemoveThisType or auraInstance.aura.auraType == onlyRemoveThisType)
        and (not onlyCausedByThisUnit or auraInstance.causer and auraInstance.causer == onlyCausedByThisUnit)
        then
            if dispelMode ~= DispelMode.Latest then
                if auraInstance.causer then
                    replicatedRemove(auraInstance.causer.castAuras, auraInstance)
                end
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
        if latestAura.causer then
            replicatedRemove(latestAura.causer.castAuras, latestAura)
        end
        markedForRemoval[latestAura] = true
    end

    local removedAurasForReturn = {}
    for i, _ in pairs(markedForRemoval) do
        local auraInstance = fromUnit.auras.noproxy[i]
        if auraInstance then
            removedAurasForReturn[#removedAurasForReturn + 1] = auraInstance
        end
    end
    replicatedUnindex(fromUnit.auras, markedForRemoval) --TODO: May need to finalize each aura to clear connections

    return removedAurasForReturn
end

Spell.RemoveAuraInstance = function(fromUnit, auraInst)
    if auraInst.causer then
        replicatedRemove(auraInst.causer.castAuras, auraInst)
    end
    replicatedRemove(fromUnit.auras, auraInst)
end

local function removeAura(args)
    return function(spell, castingUnit, spellTarget, _)
        Spell.RemoveAura(spellTarget, args.aura, args.dispelMode, args.amount, args.removalMode, args.removeType, args.causedByCasterOnly and castingUnit or args.causedByTargetOnly and spellTarget or nil)
    end
end

local function spellSteal(args)
    return function(_, castingUnit, spellTarget, _)
        --We assume spell steals will only ever steal beneficial effects
        local removedAuras = Spell.RemoveAura(spellTarget, args.dispelType, args.dispelMode, args.amount, AuraRemovalMode.ByDispelType, AuraType.Buff)
        for _, auraInstance in ipairs(removedAuras) do
            replicatedInsert(castingUnit.auras, auraInstance)
        end
    end
end

local function projectile(args)
    return function(spell, castingUnit, spellTarget, spellLocation)
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
        wait(spd)
        local fn = args.onArriveWorldModel
        if fn then
            fn(workspace.Dummy)
        end
        fb.Anchored = true
        fb.Transparency = 1
        delay(2, function()
            fb:Destroy()
        end)
    end
end

local function multi(args) --Wrap multiple effects in a single function, preserving order
    return function(...)
        for i, v in ipairs(args) do
            v(...)
        end
    end
end

local function ifHasAura(aura)
    return function(args)
        return function(spell, castingUnit, spellTarget, spellLocation)
            local effect = args.effect or args[1]
            local compoundReturn = false

            if castingUnit:hasAura(aura) then
                compoundReturn = args.dropFollowingEffects
                compoundReturn = effect(spell, castingUnit, spellTarget, spellLocation) or compoundReturn
            end

            return compoundReturn
        end
    end
end

local function ifNotHasAura(aura)
    return function(args)
        return function(spell, castingUnit, spellTarget, spellLocation)
            local effect = args.effect or args[1]
            local compoundReturn = false

            if not castingUnit:hasAura(aura) then
                compoundReturn = args.dropFollowingEffects
                compoundReturn = effect(spell, castingUnit, spellTarget, spellLocation) or compoundReturn
            end

            return compoundReturn
        end
    end
end

local function ifKnowsSpell(preSpell)
    return function(args)
        return function(spell, castingUnit, spellTarget, spellLocation)
            local effect = args.effect or args[1]
            local compoundReturn = false

            if castingUnit.charsheet.spellbook:hasSpell(preSpell) then
                compoundReturn = args.dropFollowingEffects
                compoundReturn = effect(spell, castingUnit, spellTarget, spellLocation) or compoundReturn
            end

            return compoundReturn
        end
    end
end

local function ifSpecAndLevel(spec, level)
    return function(args)
        return function(spell, castingUnit, spellTarget, spellLocation)
            local effect = args.effect or args[1]
            local compoundReturn = false

            if castingUnit.charsheet.spec == spec and castingUnit.charsheet.level >= level then
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
    end,
    AllPartyMembers = function(_, castingUnit, _, _)
        if not castingUnit or not castingUnit.is or not castingUnit:is"PlayerUnit" then
            --Caster has to be a player
        elseif castingUnit.is and castingUnit:is("PlayerUnit") then
            if castingUnit.party then
                return castingUnit.party.units.noproxy
            end
        end
        return {castingUnit}
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
    tooltip = function(sheet) return "Applies a dummy aura to the target." end,
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

    modifyAttack = false,

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
        ifHasAura(Auras.HotStreak) { --Do not do anything if already has aura
            dropFollowingEffects = true,
            effect = spellDummy(),
        },
        ifHasAura(Auras.HeatingUp) { --If already Heating Up, apply Hot Streak
            dropFollowingEffects = true,
            effect = multi {
                removeAura { --Remove Heating Up
                    aura = Auras.HeatingUp,
                    dispelMode = DispelMode.All
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

    modifyAttack = false,

    school = Schools.Fire,
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
        str = str .. Linebreak .. "If cast on a party member, everyone in the party gains the same bonus."
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.04,

    cooldown = 0,
    gcd = GCD.Standard,

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

    modifyAttack = false,

    school = Schools.Fire,
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

    modifyAttack = true,

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

    modifyAttack = false,

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

Spells.Corruption = Spell.new()
Spells.Corruption:assign({
    name = "Corruption",
    tooltip = function(sheet)
        local str = "Corrupts the target, causing "
        if sheet.spec == Specs.Affliction and sheet.level >= 54 then
            str = str .. "%s Shadow damage and an additional "
        end
        str = str .. "%s Shadow damage over %s seconds."
        if sheet.spec == Specs.Affliction then
            str = str .. Linebreak .. "Generates 2 Fel Energy per second for each affected target."
        end
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = 0.01,

    cooldown = 0,
    gcd = GCD.Standard,

    castType = function(sheet)
        if sheet.spec == Specs.Affliction and sheet.level >= 4 then
            return CastType.Instant
        end
        return CastType.Casting
    end,
    castTime = 2,
    targetType = TargetType.Enemy,
    range = Range.Long,

    modifyAttack = false,

    school = Schools.Shadow,
    effects = {
        ifSpecAndLevel(Specs.Affliction, 54) {
            schoolDamage {
                school = Schools.Shadow,
                damage = function(caster, sheet)
                    return 0.14 * sheet:spellPower(caster)
                end,
            },
        },
        applyAura {
            aura = Auras.Corruption,
            auraData = {
                duration = 14,
            },
        },
    },
})

Spells.Agony = Spell.new()
Spells.Agony:assign({
    name = "Agony",
    tooltip = function(sheet)
        local str = "The target writhes in agony, causing %s Shadow damage over %s seconds. Damage ramps up over time."
        if sheet.spec == Specs.Affliction then
            str = str .. Linebreak .. "Dealing Agony damage generates 4 Fel Energy, reduced for enemies beyond the first."
        end
        return str
    end,
    icon = "rbxassetid://1337",
    resource = Resources.Mana,
    resourceCost = 0.01,
    cooldown = 0,
    gcd = GCD.Standard,
    castType = CastType.Instant,
    targetType = TargetType.Enemy,
    range = Range.Long,
    modifyAttack = false,
    school = Schools.Shadow,
    effects = {
        applyAura {
            aura = Auras.Agony,
            auraData = {
                duration = 18,
                stacks = function(sheet)
                    if sheet.spellbook:hasSpell(Spells.WritheInAgony) then
                        return 4
                    end
                    return 1
                end,
            },
        },
    },
})

Spells.AfflictionFelEnergy = Spell.new()
Spells.AfflictionFelEnergy:assign({
    name = "Fel Energy",
    tooltip = function(sheet)
        local str = "Your afflictions generate Fel Energy. Fel Energy is used to fuel your draining abilities."
        return str
    end,
    icon = "rbxassetid://1337",
    castType = CastType.Passive,
    school = Schools.Physical
})

Spells.WritheInAgony = Spell.new()
Spells.WritheInAgony:assign({
    name = "Writhe in Agony",
    tooltip = function(sheet)
        local str = "Agony starts at 4 stacks and may ramp up to 18 stacks."
        return str
    end,
    icon = "rbxassetid://1337",
    castType = CastType.Passive,
    school = Schools.Physical
})

Spells.Kleptomancy = Spell.new()
Spells.Kleptomancy:assign({
    name = "Kleptomancy",
    tooltip = function(sheet)
        local str = "Spellsteal steals all beneficial Magic effects from the target, costs 300% more Mana, and has a 30sec cooldown."
        return str
    end,
    icon = "rbxassetid://1337",
    castType = CastType.Passive,
    school = Schools.Physical,
})

Spells.Spellsteal = Spell.new()
Spells.Spellsteal:assign({
    name = "Spellsteal",
    tooltip = function(sheet)
        local str = "Remove "
        if sheet.spellbook:hasSpell(Spells.Kleptomancy) then
            str = str .. "all beneficial Magic effects from an enemy, gaining them for yourself."
            str = str .. Linebreak .. "These effects"
        else
            str = str .. "one beneficial Magic effect from an enemy, gaining it for yourself."
            str = str .. Linebreak .. "The effect"
        end
        str = str .. " will last a maximum of 2 min."
        return str
    end,
    icon = "rbxassetid://1337",

    resource = Resources.Mana,
    resourceCost = function(sheet)
        local mod = 1
        if sheet.spellbook:hasSpell(Spells.Kleptomancy) then
            mod = mod + 3
        end
        return 0.21 * mod
    end,

    cooldown = function(sheet)
        if sheet.spellbook:hasSpell(Spells.Kleptomancy) then
            return 30
        else
            return 5
        end
    end,
    gcd = GCD.Standard,

    castType = CastType.Instant,
    targetType = TargetType.Enemy,
    range = Range.Long,

    modifyAttack = false,

    school = Schools.Arcane,
    effects = {
        ifKnowsSpell(Spells.Kleptomancy) {
            dropFollowingEffects = true,
            spellSteal {
                dispelType = AuraDispelType.Magic,
                dispelMode = DispelMode.All,
            },
        },
        spellSteal {
            dispelType = AuraDispelType.Magic,
            dispelMode = DispelMode.Latest
        },
    },
})

Spells.ImprovedBlock = Spell.new()
Spells.ImprovedBlock:assign({
    name = "Block Succession",
    tooltip = function(sheet)
        local str = "After you critical block an attack, increase your Block by %s%% for %s seconds."
        return str
    end,
    icon = "rbxassetid://1337",
    castType = CastType.Passive,
    school = Schools.Physical,
})

Spells.ImprovedShieldBash = Spell.new()
Spells.ImprovedShieldBash:assign({
    name = "Counter Bash",
    tooltip = function(sheet)
        local str = "Shield Bash has a %s%% chance to regain a charge after blocking an attack."
        return str
    end,
    icon = "rbxassetid://1337",
    castType = CastType.Passive,
    school = Schools.Physical,
})

Spells.ShieldWall = Spell.new()
Spells.ShieldWall:assign({
    name = "Shield Wall",
    tooltip = function(sheet)
        local str = "Ready your shield, reducing damage taken from attacks by %s%% for %s seconds."
        return str
    end,
    icon = "rbxassetid://1337",
    
    gcd = GCD.Standard,
    cooldown = 25,
    castType = CastType.Instant,
    targetType = TargetType.Self,
    range = Range.Self,

    school = Schools.Physical,
    effects = {
        applyAura {
            aura = Auras.ShieldWall,
            auraData = {
                duration = 6,
            },
        },
    }
})

Spells.DrainLife = Spell.new()
Spells.DrainLife:assign({
    name = "Drain Life",
    tooltip = function(sheet)
        local str = "Steal your target's life force, dealing %s Shadow damage over %s seconds and healing you for %s%% of the damage dealt."
        return str
    end,
    icon = "rbxassetid://1337",
    resource = Resources.FelEnergy,
    resourceCost = 0,
    cooldown = 0,
    gcd = GCD.Standard,
    castType = CastType.Channeled,
    channelDuration = 6,
    channelCost = 10,
    targetType = TargetType.Enemy,
    range = Range.Long,
    modifyAttack = false,
    school = Schools.Shadow,
    effects = {
        channelAura {
            aura = Auras.DrainLife,
            auraData = {
                duration = 18,
            },
        },
    },
})

Spells.Vicious = Spell.new()
Spells.Vicious:assign({
    name = "Vicious",
    tooltip = function(sheet)
        local str = "Gain %s%% Haste."
        return str
    end,
    icon = "rbxassetid://1337",
    castType = CastType.PermanentAura,
    school = Schools.Physical,
    permanentAura = Auras.Vicious,
})

local generalArmorProf = {
    name = "Armor Proficiency",
    icon = "rbxassetid://1337",
    castType = CastType.Passive,
    school = Schools.Physical,
}

do
    Spells.WarriorArmorProfiency = Spell.new()
    Spells.WarriorArmorProfiency:assign(generalArmorProf)
    Spells.WarriorArmorProfiency:assign({
        tooltip = function(sheet)
            local str = "Warriors can wear cloth, leather and plate armor."
            str = str .. Linebreak .. "Starting at level 24, gain %s%% increased primary stats for wearing full plate armor."
            return str
        end,
        effect = applyAura {
            aura = Auras.WarriorArmorProficiency
        },
    })

    Spells.MageArmorProfiency = Spell.new()
    Spells.MageArmorProfiency:assign(generalArmorProf)
    Spells.MageArmorProfiency:assign({
        tooltip = function(sheet)
            local str = "Mages can wear cloth armor."
            str = str .. Linebreak .. "Starting at level 24, gain %s%% increased primary stats for wearing full cloth armor."
            return str
        end,
        effect = applyAura {
            aura = Auras.MageArmorProficiency
        },
    })

    Spells.HunterArmorProfiency = Spell.new()
    Spells.HunterArmorProfiency:assign(generalArmorProf)
    Spells.HunterArmorProfiency:assign({
        tooltip = function(sheet)
            local str = "Hunters can wear cloth and leather armor."
            str = str .. Linebreak .. "Starting at level 24, gain %s%% increased primary stats for wearing full leather armor."
            return str
        end,
        effect = applyAura {
            aura = Auras.HunterArmorProficiency
        },
    })

    Spells.PaladinArmorProfiency = Spell.new()
    Spells.PaladinArmorProfiency:assign(generalArmorProf)
    Spells.PaladinArmorProfiency:assign({
        tooltip = function(sheet)
            local str = "Paladins can wear cloth, leather and plate armor."
            str = str .. Linebreak .. "Starting at level 24, gain %s%% increased primary stats for wearing full plate armor."
            return str
        end,
        effect = applyAura {
            aura = Auras.PaladinArmorProficiency
        },
    })

    Spells.PriestArmorProfiency = Spell.new()
    Spells.PriestArmorProfiency:assign(generalArmorProf)
    Spells.PriestArmorProfiency:assign({
        tooltip = function(sheet)
            local str = "Priests can wear cloth armor."
            str = str .. Linebreak .. "Starting at level 24, gain %s%% increased primary stats for wearing full cloth armor."
            return str
        end,
        effect = applyAura {
            aura = Auras.PriestArmorProficiency
        },
    })

    Spells.RogueArmorProfiency = Spell.new()
    Spells.RogueArmorProfiency:assign(generalArmorProf)
    Spells.RogueArmorProfiency:assign({
        tooltip = function(sheet)
            local str = "Rogues can wear cloth and leather armor."
            str = str .. Linebreak .. "Starting at level 24, gain %s%% increased primary stats for wearing full leather armor."
            return str
        end,
        effect = applyAura {
            aura = Auras.RogueArmorProficiency
        },
    })

    Spells.DruidArmorProfiency = Spell.new()
    Spells.DruidArmorProfiency:assign(generalArmorProf)
    Spells.DruidArmorProfiency:assign({
        tooltip = function(sheet)
            local str = "Druids can wear cloth and leather armor."
            str = str .. Linebreak .. "Starting at level 24, gain %s%% increased primary stats for wearing full leather armor."
            return str
        end,
        effect = applyAura {
            aura = Auras.DruidArmorProficiency
        },
    })

    Spells.WarlockArmorProfiency = Spell.new()
    Spells.WarlockArmorProfiency:assign(generalArmorProf)
    Spells.WarlockArmorProfiency:assign({
        tooltip = function(sheet)
            local str = "Warlocks can wear cloth armor."
            str = str .. Linebreak .. "Starting at level 24, gain %s%% increased primary stats for wearing full cloth armor."
            return str
        end,
        effect = applyAura {
            aura = Auras.WarlockArmorProficiency
        },
    })
end

Spells.Bloodlust = Spell.new()
Spells.Bloodlust:assign({
    name = "Bloodlust",
    tooltip = function(sheet)
        local str = "For the next %s%% seconds, your Haste is increased by %s%%."
        str = str .. Linebreak .. "If cast while in a party, all party members gain the bonus."
        return str
    end,
    icon = "rbxassetid://1337",
    castType = CastType.Instant,
    cooldown = 5 * 60,
    gcd = GCD.None,
    targetType = TargetType.Self,
    range = Range.Self,
    school = Schools.Physical,
    effects = {
        onEach {
            collector = collectors.AllPartyMembers,
            effect = {
                ifNotHasAura(Auras.Exhaustion) {
                    multi {
                        applyAura {
                            aura = Auras.Bloodlust,
                            auraData = {
                                duration = 30,
                            },
                        },
                        applyAura {
                            aura = Auras.Exhaustion,
                            auraData = {
                                duration = 10 * 60,
                            },
                        }
                    }
                }
            },
        }
    },
})





Spells.StartAttack = Spell.new()
Spells.StartAttack:assign({
    name = "Attack",
    tooltip = function(sheet)
        if sheet.equipment:has(Slots.MainHand) and sheet.equipment:has(Slots.OffHand) and sheet:canDualWield() then
            return "Start attacking your target with both weapons."
        end
        return "Start attacking your target with your main hand weapon."
    end,

    targetType = TargetType.Enemy,
    range = Range.Unlimited,
    losRequired = false,    --We can initiate attack without face or LOS,
    facingRequired = false, --both are checked in the unit script.

    modifyAttack = true,

    --[[effects = {
        --startAttack
    }]]
})

return Spell