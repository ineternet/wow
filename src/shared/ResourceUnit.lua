local ContextActionService = game:GetService("ContextActionService")
setfenv(1, require(script.Parent.Global))

local ResourceUnit = use"TargetUnit".inherit"ResourceUnit"

ResourceUnit.SoulFragmentsRegenerateTo = 3 --How many soul fragments should be the out of combat default
ResourceUnit.SoulFragmentsRegenTimeout = 4 --How many seconds between each soul fragment regen
ResourceUnit.DropCombatFromOwnActionTimeout = 5 --How long before combat drops if this unit the only attacker (no one is aggroed)

ResourceUnit.inferPrimary = function(fromClass, fromSpec)
    return ({
        [Classes.Classless] = Resources.Health,
        [Classes.Warrior] = Resources.Health,
        [Classes.Mage] = Resources.Health,
        [Classes.Hunter] = Resources.Health,
        [Classes.Paladin] = Resources.Health,
        [Classes.Priest] = Resources.Health,
        [Classes.Rogue] = Resources.Health,
        [Classes.Druid] = Resources.Health,
        [Classes.Warlock] = Resources.Health,
    })[fromClass] or Resources.None
end

ResourceUnit.inferSecondary = function(fromClass, fromSpec)
    return ({
        [Classes.Classless] = Resources.None,
        [Classes.Warrior] = Resources.Fury,
        [Classes.Mage] = Resources.Mana,
        [Classes.Hunter] = Resources.Focus,
        [Classes.Paladin] = Resources.Mana,
        [Classes.Priest] = Resources.Mana,
        [Classes.Rogue] = Resources.Energy,
        [Classes.Druid] = Resources.Mana,
        [Classes.Warlock] = Resources.Mana,
    })[fromClass] or Resources.None
end

ResourceUnit.inferTertiary = function(fromClass, fromSpec)
    return ({
        [Specs.Frost] = Resources.Icicles,
        [Specs.Divination] = Resources.Favors,
        [Specs.Void] = Resources.Corruption,
        [Specs.Demonology] = Resources.SoulFragments,
        [Specs.Affliction] = Resources.FelEnergy
    })[fromSpec] or ({
        [Classes.Classless] = Resources.None,
        [Classes.Rogue] = Resources.ComboPoints,
        [Classes.Druid] = Resources.Energy,
    })[fromClass] or Resources.None
end

ResourceUnit.inferQuaternary = function(fromClass, fromSpec)
    return ({
        [Classes.Druid] = Resources.Fury,
    })[fromClass] or Resources.None
end

ResourceUnit.inferQuinary = function(fromClass, fromSpec)
    return ({
        [Classes.Druid] = Resources.ComboPoints,
    })[fromClass] or Resources.None
end

ResourceUnit.manaAt = function(sheet)
    local mod = 1
    if table.find({
        Classes.Mage,
        Classes.Priest,
        Classes.Warlock,
    }, sheet.class) then
        mod = 5
    end
    return mod * BaseMana[sheet.level]
end

ResourceUnit.inferMaximum = function(self, forResource, fromSheet)
    if not fromSheet then
        return 0
    end
    return ({
        [Resources.None] = 0,
        [Resources.Mana] = ResourceUnit.manaAt(fromSheet),
        [Resources.Health] = fromSheet:stamina(self) * 10,
        [Resources.Fury] = 100,
        [Resources.Focus] = 100,
        [Resources.Energy] = 100,
        [Resources.Corruption] = 100,
        [Resources.Icicles] = 5,
        [Resources.Favors] = 5,
        [Resources.FelEnergy] = 200,
        [Resources.SoulFragments] = 6,
        [Resources.ComboPoints] = 5,
    })[forResource] or nil
end

--Unit class that enables resources and casting.

ResourceUnit.new = Constructor(ResourceUnit, {
    primaryResource = Resources.Health,     --Usually health
    secondaryResource = Resources.None,     --Usually mana or mana replacement
    tertiaryResource = Resources.None,      --Usually spec resource for mana users
    quaternaryResource = Resources.None,    --Druid bear form
    quinaryResource = Resources.None,       --Druid combo points

    primaryResourceAmount = 1,
    secondaryResourceAmount = 0,
    tertiaryResourceAmount = 0,
    quaternaryResourceAmount = 0,
    quinaryResourceAmount = 0,

    primaryResourceMaximum = 1,
    secondaryResourceMaximum = 0,
    tertiaryResourceMaximum = 0,
    quaternaryResourceMaximum = 0,
    quinaryResourceMaximum = 0,

    currentAction = Actions.Idle,
    actionBegin = utctime(),
    actionEnd = utctime(),
    gcdEnd = utctime(),
    interruptCast = nil,

    mainSwingPassed = 0,
    mainSwinging = false,
    offSwingPassed = 0,
    offSwinging = false,

    lastAggressiveAction = utctime(),

    soulFragmentRegenTick = utctime(),

}, function(self, charsheet)
    table.insert(self.eventConnections, ConnectToHeartbeat(function(dt)
        self:tick(dt)
    end))
end)

ResourceUnit.startMainHandSwing = function(self, after)
    if not self.charsheet.equipment:has(Slots.MainHand) or not self.charsheet.equipment:get(Slots.MainHand):swingable() then
        return
    end
    if self.interruptCast then
        self.interruptCast()
    end
    self.currentAction = Actions.Swing
    self.actionBegin = utctime()
    self.actionEnd = utctime() --TODO: verify interactions
    local contfn = function()
        self.mainSwinging = true
    end
    if after <= 0 then --Im not sure if task.delay(0) immediately executes
        contfn()
    else
        delay(after, contfn)
    end
end

ResourceUnit.startOffHandSwing = function(self, after)
    if not self.charsheet.equipment:has(Slots.OffHand) or not self.charsheet.equipment:get(Slots.OffHand):swingable() then
        return
    end
    if self.interruptCast then
        self.interruptCast()
    end
    self.currentAction = Actions.Swing
    self.actionBegin = utctime()
    self.actionEnd = utctime() --TODO: verify interactions
    local contfn = function()
        self.offSwinging = true
    end
    if after <= 0 then --Im not sure if task.delay(0) immediately executes
        contfn()
    else
        delay(after, contfn)
    end
end

ResourceUnit.stopMainHandSwing = function(self)
    self.mainSwinging = false
    if self.currentAction == Actions.Swing and not self.offSwinging then
        self.currentAction = Actions.Idle
    end
end

ResourceUnit.stopOffHandSwing = function(self)
    self.offSwinging = false
    if self.currentAction == Actions.Swing and not self.mainSwinging then
        self.currentAction = Actions.Idle
    end
end

ResourceUnit.getPool = function(self, resourceType)
    for _, pool in ipairs({
        "primaryResource",
        "secondaryResource",
        "tertiaryResource",
        "quaternaryResource",
        "quinaryResource",
    }) do
        if self[pool] == resourceType then
            return pool
        end
    end
end

ResourceUnit.getResourceAmount = function(self, resourceType)
    local pool = self:getPool(resourceType)
    if pool then
        return self[("%sAmount"):format(pool)]
    else
        return 0
    end
end

ResourceUnit.setResourceAmount = function(self, resourceType, amount)
    assert(amount >= 0, "Resource amount must be non-negative.")
    assert(Resources[resourceType], "Resource type must be a valid resource.")

    if IntegerResources[resourceType] and math.floor(amount) ~= amount then
        warn("Tried to create non-integer value for resource " .. resourceType .. ", will be rounded. Original value:", amount)
        amount = math.floor(amount)
    end

    local pool = self:getPool(resourceType)
    if pool then
        if self[("%sAmount"):format(pool)] == amount then
            return --Avoid unnecessary updates
        end
        self[("%sAmount"):format(pool)] = math.clamp(amount, 0, self[("%sMaximum"):format(pool)])
    end
end

--@return false if the resource was capped (not changed by the full amount)
--@return the amount that was actually added (or removed)
ResourceUnit.deltaResourceAmount = function(self, resourceType, amount)
    local before = self:getResourceAmount(resourceType)
    local clampedVal = math.clamp(before + amount, 0, self:getResourceMaximum(resourceType))
    self:setResourceAmount(resourceType, clampedVal)
    return clampedVal == before + amount, clampedVal - before
end

--@return true if changing the resource by this much would NOT cause an underflow
ResourceUnit.canAfford = function(self, resourceType, amount)
    return self:getResourceAmount(resourceType) + amount >= 0
end

ResourceUnit.getResourceMaximum = function(self, resourceType)
    local pool = self:getPool(resourceType)
    if pool then
        return self[("%sMaximum"):format(pool)]
    else
        return 0
    end
end

ResourceUnit.setResources = function(self, class, spec)
    self.primaryResource = ResourceUnit.inferPrimary(class, spec)
    self.secondaryResource = ResourceUnit.inferSecondary(class, spec)
    self.tertiaryResource = ResourceUnit.inferTertiary(class, spec)
    self.quaternaryResource = ResourceUnit.inferQuaternary(class, spec)
    self.quinaryResource = ResourceUnit.inferQuinary(class, spec)
    self.primaryResourceMaximum = self:inferMaximum(self.primaryResource, self.charsheet)
    self.secondaryResourceMaximum = self:inferMaximum(self.secondaryResource, self.charsheet)
    self.tertiaryResourceMaximum = self:inferMaximum(self.tertiaryResource, self.charsheet)
    self.quaternaryResourceMaximum = self:inferMaximum(self.quaternaryResource, self.charsheet)
    self.quinaryResourceMaximum = self:inferMaximum(self.quinaryResource, self.charsheet)
end

ResourceUnit.updateClassResources = function(self)
    self:setResources(self.charsheet.class, self.charsheet.spec)
end

ResourceUnit.onAuraChange = ResourceUnit.updateClassResources
ResourceUnit.onEquipmentChange = ResourceUnit.updateClassResources
ResourceUnit.onClassChange = ResourceUnit.updateClassResources
ResourceUnit.onSpecChange = ResourceUnit.updateClassResources
ResourceUnit.onTalentChange = ResourceUnit.updateClassResources

--Function for implementing special cases for resources:
--  - Mana (amount is given as base mana percentage)
ResourceUnit.resolveRaw = function(self, resourceType, amount)
    if resourceType == Resources.Mana then
        amount = self.charsheet:baseMana() * amount
    end
    return amount
end

ResourceUnit.hardCast = function(self, spell, spellTarget, spellLocation) --For casts
    if self.currentAction == Actions.Cast then
        return false
    end
    self.currentAction = Actions.Cast
    self.actionBegin = utctime()
    self.actionEnd = utctime() + (spell.castTime or 0)
    self.gcdEnd = utctime() + self.charsheet:gcd(self, spell.gcd or GCD.None)
    self.lastSpell = ref(spell)

    local interrupted = false
    self.interruptCast = function()
        self.currentAction = (self.mainSwinging or self.offSwinging) and Actions.Swing or Actions.Idle
        interrupted = true
    end
    local castDuration = self.actionEnd - utctime()
    castDuration = castDuration / (1 + self.charsheet:haste(self))
    delay(castDuration, function()
        if not interrupted then
            if spell.resourceCost then
                self:deltaResourceAmount(spell.resource, -self:resolveRaw(spell.resource, resolveNumFn(spell.resourceCost, self.charsheet)))
            end
            self.currentAction = (self.mainSwinging or self.offSwinging) and Actions.Swing or Actions.Idle
            for order, effect in ipairs(spell.effects) do
                if effect(spell, self, spellTarget, spellLocation) then
                    break
                end
            end
        end
    end)
    return true
end

ResourceUnit.channelCast = function(self, spell, spellTarget, spellLocation) --For channels
    self.currentAction = Actions.Channel
    self.actionBegin = utctime()
    self.actionEnd = utctime() + (spell.channelDuration or 0)
    self.gcdEnd = utctime() + self.charsheet:gcd(self, spell.gcd or GCD.None)
    self.lastSpell = ref(spell)

    local interrupted = false
    self.interruptCast = function()
        self.currentAction = (self.mainSwinging or self.offSwinging) and Actions.Swing or Actions.Idle
        interrupted = true
    end
    if spell.resourceCost then
        self:deltaResourceAmount(spell.resource, -self:resolveRaw(spell.resource, resolveNumFn(spell.resourceCost, self.charsheet)))
    end
    local castDuration = self.actionEnd - utctime()
    castDuration = castDuration / (1 + self.charsheet:haste(self))
    for order, effect in ipairs(spell.effects) do
        if effect(spell, self, spellTarget, spellLocation) then
            break
        end
    end



    return true
end

ResourceUnit.instantCast = function(self, spell, spellTarget, spellLocation) --For instant casts
    local isMidCastCast = false
    if self.currentAction == Actions.Cast then
        if not spell.castableWhileCasting(self) then
            self.interruptCast()
        else
            isMidCastCast = true
        end
    end

    local thisSpellGcdEnd = utctime() + self.charsheet:gcd(self, spell.gcd or GCD.None)

    if not isMidCastCast then --If this is a mid-cast cast, preserve the old information
        self.currentAction = (self.mainSwinging or self.offSwinging) and Actions.Swing or Actions.Idle --We immediately go to idle because the cast is instant
        self.actionBegin = utctime()
        self.actionEnd = utctime() --Duh
        self.lastSpell = ref(spell)
    end
    self.gcdEnd = math.max(self.gcdEnd, thisSpellGcdEnd) --If the old GCD would have ended later, preserve it

    if spell.resourceCost then
        self:deltaResourceAmount(spell.resource, -self:resolveRaw(spell.resource, resolveNumFn(spell.resourceCost, self.charsheet)))
    end
    for order, effect in ipairs(spell.effects) do
        if effect(spell, self, spellTarget, spellLocation) then
            break
        end
    end

    return true
end

ResourceUnit.passiveCast = function(self, spell, spellTarget, spellLocation) --For passive procs
    --We dont set any timers or the last spell here

    if spell.resourceCost then
        self:deltaResourceAmount(spell.resource, -self:resolveRaw(spell.resource, resolveNumFn(spell.resourceCost, self.charsheet)))
    end

    for order, effect in ipairs(spell.effects) do
        if effect(spell, self, spellTarget, spellLocation) then
            break
        end
    end

    return true
end

ResourceUnit.die = void

ResourceUnit.canCast = function(self, spell, target, location)
    --Check if we can cast the spell
    -- 1 Check if we have enough resources, if the spell has a resource cost
    -- 2 Check if we are in range
    -- 3 Check if we are in line of sight, if required
    -- 4 Check if we are facing the target, if applicable and required
    -- 5 Check if global cooldown is up, or if we are casting a spell that doesn't have a GCD
    -- 6 Check if we are in a busy action, or if we are casting a spell that doesn't interrupt
    -- 7 Check if Spellbook agrees that the spell is off cooldown
    -- 8 Check if we are kicked, if the spell is affected and in that school
    -- 9 Check if for any impairing effects, or the spell is castable while impaired

    --1
    if spell.resourceCost then
        local resourceAmount = self:getResourceAmount(spell.resource)
        local resourceCost = self:resolveRaw(spell.resource, resolveNumFn(spell.resourceCost, self.charsheet))
        if resourceAmount < resourceCost then
            return false, "Not enough " .. ResourceNames[spell.resource]
        end
    end

    --2
    if target and (spell.range or 0) > 0 and false  then
        local distance = target:distanceFrom(self.location)
        if distance > spell.range then
            return false, "Out of range"
        end
    end

    --3
    local defaultLosRule = (LosRules)[spell.targetType or TargetType.Self]
    local shouldCheckLos = (spell.losRequired == nil) and defaultLosRule or spell.losRequired
    if target and shouldCheckLos then
        if not self:los(target) then
            return false, "Target not in line of sight"
        end
    end

    --4
    local defaultFacingRule = (FacingRules)[spell.targetType or TargetType.Self]
    local shouldCheckFacing = (spell.facingRequired == nil) and defaultFacingRule or spell.facingRequired
    if target and shouldCheckFacing then
        local facing = self:facing(target)
        if not facing then
            return false, "Facing in the wrong direction"
        end
    end

    --5
    if self.gcdEnd and utctime() < self.gcdEnd then
        return false, "Not ready yet"
    end

    --6
    if self.currentAction ~= Actions.Idle --Can override idle
    and self.currentAction ~= Actions.Swing then --Can override swinging (some spells will stop this)
        if self.currentAction == Actions.Dead then
            return false, "You are dead..."
        end

        --Spells can be overriden, for now
        --The exact mechanic is resolved by the cast function
        --[[if not spell.castableWhileCasting(self) then
            return false, "Busy"
        end]]
    end

    --7
    local ready, whyNot = self.charsheet.spellbook:ready(spell)
    if not ready then
        return false, whyNot or "Spell is not ready"
    end

    --8
    

    --9

    return true, ""
end

ResourceUnit.targetUnit = function(self, otherUnit)
    self.target = ref(otherUnit)
end

ResourceUnit.startAttack = function(self, spellTarget)
    self:targetUnit(spellTarget or self.target)
    if self.currentAction == Actions.Swing then
        return --Do not unnecessarily reset swing timer
    end
    self:startMainHandSwing(0)
    self:startOffHandSwing(0.15)
end

ResourceUnit.stopAttack = function(self)
    Effects.StopMeleeSwing()
    self:stopMainHandSwing()
    self:stopOffHandSwing()
end

ResourceUnit.cast = function(self, spell, target, location)
    --We assume a previous function has checked if the spell is off cooldown

    local casttype = spell.castType
    local spellidx = spell.index --To avoid an error on the client

    local target = target or self.target
    local location = location or self.location

    --Even if the cast will fail, modify attack status if the spell requires it
    --Mostly QoL, the point is to be able to initiate combat even when casting out of range
    if spell.modifyAttack ~= nil then
        if spell.modifyAttack then
            self:startAttack(target)
        else
            self:stopAttack()
        end
    end

    --Check for cast type modifiers from auras
    --For example some passive procs will cause auras that turn some spells into instant casts.
    for _, aura in ipairs(self.auras.noproxy) do
        if aura.aura.modCastType then
            local thisSpellMod = aura.aura.modCastType[spellidx]
            if thisSpellMod then
                casttype = thisSpellMod
                if aura.aura.onQuery then
                    aura.aura.onQuery(aura, self, spell, target, location)
                end
                break
            end
        end
    end

    if not casttype then
        warn("No cast type for spell " .. spell.name .. " assuming Instant")
        casttype = CastType.Instant
    end

    if spell.targetType == TargetType.Self then
        target = self
    elseif spell.targetType == TargetType.Friendly then
        print(self:isFriendly(target), "<- friendly. DEBUG: FALLING BACK TO SELF")
        target = self
    elseif spell.targetType == TargetType.Enemy then
        assert(self:isEnemy(target), "Target is not enemy")
    elseif spell.targetType == TargetType.Area then
        assert(location, "No location for area spell")
    elseif spell.targetType == TargetType.Party then
        assert(self:isFriendly(target), "Target is not friendly")
        --TODO: check party
    elseif spell.targetType == TargetType.Any then
        assert(target, "No target for Any spell")
    else
        error("Unknown target type " .. tostring(spell.targetType))
    end

    ({
        [CastType.Instant] = ResourceUnit.instantCast,
        [CastType.Channeled] = ResourceUnit.channelCast,
        [CastType.Casting]    = ResourceUnit.hardCast,
        [CastType.Passive] = ResourceUnit.passiveCast,
    })[resolveNumFn(casttype, self.charsheet)](self, spell, target, location)

    self.charsheet.spellbook:postCast(spell, self)

    return true
end

ResourceUnit.wantToCast = function(self, spell, target, location) --On user input, on npc logic
    local target = target or self.target
    local location = location or self.location

    local canCast, reason = self:canCast(spell, target, location)
    if not canCast then
        return false, reason
    end

    return self:cast(spell, target, location), ""
end

ResourceUnit.takeDamage = function(self, damage, school, sourceUnit)
    assert(tonumber(damage), "Damage must be a number.")
    assert(damage >= 0, "Damage must be positive.")
    assert(school ~= nil, "School must be specified.")
    assert(self:getPool(Resources.Health), "Cannot damage healthless unit.")

    local isMassiveDamage = damage > self.primaryResourceMaximum
    local postMitigation = self.charsheet:mitigate(self, sourceUnit and sourceUnit.charsheet, damage, school, isMassiveDamage)

    self.primaryResourceAmount = math.max(self.primaryResourceAmount - postMitigation, 0)
    if self.primaryResourceAmount <= 0 then
        self:die()
    end
end

ResourceUnit.receiveHeal = function(self, damage, school, sourceUnit)
    assert(tonumber(damage), "Damage must be a number.")
    assert(damage >= 0, "Damage must be positive.")
    assert(school ~= nil, "School must be specified.")
    assert(self:getPool(Resources.Health), "Cannot heal healthless unit.")
    assert(self.primaryResourceAmount > 0, "Cannot heal dead unit.")

    self.primaryResourceAmount = math.min(self.primaryResourceAmount + damage, self.primaryResourceMaximum)
end

ResourceUnit.aggroedUnits = function(self)
    return 0
end

ResourceUnit.isInCombat = function(self)
    return self:aggroedUnits() > 0 or (utctime() - self.lastAggressiveAction) < ResourceUnit.DropCombatFromOwnActionTimeout
end

ResourceUnit.tick = function(self, deltaTime)
    self:regenTick(deltaTime, self:isInCombat())

    if self.currentAction == Actions.Swing then
        if self.mainSwinging then
            local facing = self:facing(self.target)
            local los = self:los(self.target)
            local inrange = self.target:distanceFrom(self.location) <= Range.Combat
            if facing and los and inrange then --Remember swing timer when not facing for QoL
                self.mainSwingPassed = self.mainSwingPassed + deltaTime
                local timeout = self.charsheet.equipment:get(Slots.MainHand):swingTimeout()
                if self.mainSwingPassed >= timeout then
                    Effects.StartMeleeSwing(nil, timeout)
                    self.mainSwingPassed = self.mainSwingPassed - timeout
                    local dam = self.charsheet:totalMainHandDamage()
                    use"Spell".SchoolDamage(Spells.StartAttack, self, self.target, dam, Schools.Physical)
                end
            else
                Effects.StopMeleeSwing()
            end
        end
        if self.offSwinging then
            local facing = self:facing(self.target)
            local los = self:los(self.target)
            local inrange = self.target:distanceFrom(self.location) <= Range.Combat
            if facing and los and inrange then
                self.offSwingPassed = self.offSwingPassed + deltaTime
                local timeout = self.charsheet.equipment:get(Slots.OffHand):swingTimeout()
                if self.offSwingPassed >= timeout then
                    self.offSwingPassed = self.offSwingPassed - timeout
                    local dam = self.charsheet:totalOffHandDamage()
                    use"Spell".SchoolDamage(Spells.StartAttack, self, self.target, dam, Schools.Physical)
                end
            end
        end
    end

    self.charsheet.spellbook:tick(deltaTime)
    ResourceUnit.super.tick(self, deltaTime)
end

ResourceUnit.regenTick = function(self, timeSinceLastTick, inCombat)
    self:deltaResourceAmount(Resources.Health, self.charsheet:healthRegen() * timeSinceLastTick * self:getResourceMaximum(Resources.Health))
    self:deltaResourceAmount(Resources.Mana, self.charsheet:manaRegen() * timeSinceLastTick * self:getResourceMaximum(Resources.Mana))
    self:deltaResourceAmount(Resources.Energy, self.charsheet:energyRegen() * timeSinceLastTick * self:getResourceMaximum(Resources.Energy))
    self:deltaResourceAmount(Resources.Focus, self.charsheet:focusRegen() * timeSinceLastTick * self:getResourceMaximum(Resources.Focus))
    if not inCombat then
        if self:getPool("SoulFragments") and self:getResourceAmount("SoulFragments") ~= ResourceUnit.SoulFragmentsRegenerateTo then
            if (utctime() - self.soulFragmentRegenTick) > ResourceUnit.SoulFragmentsRegenTimeout then
                self.soulFragmentRegenTick = utctime()
                local direction = self:getResourceAmount("SoulFragments") > ResourceUnit.SoulFragmentsRegenerateTo and -1 or 1
                self:deltaResourceAmount("SoulFragments", direction)
            end
        end
    end
end

ResourceUnit.procCrit = function(self, spell)
    local critChance = self.charsheet:crit(self)
    if critChance >= 1 then
        return true
    elseif critChance > 0 then
        local critRoll = math.random()
        if critRoll < critChance then
            return true
        end
    end
    return false
end

return ResourceUnit