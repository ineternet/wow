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
    interruptCast = nil,

    lastAggressiveAction = utctime(),

    soulFragmentRegenTick = utctime(),

    spellbook = use"Spellbook".new,

}, function(self)
    table.insert(self.eventConnections, game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:tick(dt)
    end))
end)

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

ResourceUnit.deltaResourceAmount = function(self, resourceType, amount)
    self:setResourceAmount(resourceType, math.clamp(self:getResourceAmount(resourceType) + amount, 0, self:getResourceMaximum(resourceType)))
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
    self.gcdEnd = utctime() + self.charsheet:gcd(self, spell.gcd or GCD.Standard)
    self.lastSpell = ref(spell)

    local interrupted = false
    self.interruptCast = function()
        interrupted = true
    end
    local castDuration = self.actionEnd - utctime()
    castDuration = castDuration / (1 + self.charsheet:haste(self))
    task.delay(castDuration, function()
        if not interrupted then
            if spell.resourceCost then
                self:deltaResourceAmount(spell.resource, -self:resolveRaw(spell.resource, spell.resourceCost))
            end
            self.currentAction = Actions.Idle
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
    error("Channel casts not yet implemented.")
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

    local thisSpellGcdEnd = utctime() + self.charsheet:gcd(self, spell.gcd or GCD.Standard)

    if not isMidCastCast then --If this is a mid-cast cast, preserve the old information
        self.currentAction = Actions.Idle --We immediately go to idle because the cast is instant
        self.actionBegin = utctime()
        self.actionEnd = utctime() --Duh
        self.gcdEnd = thisSpellGcdEnd
        self.lastSpell = ref(spell)
    else --Still update GCD if the old GCD would end too early.
        self.gcdEnd = math.max(self.gcdEnd, thisSpellGcdEnd)
    end

    if spell.resourceCost then
        self:deltaResourceAmount(spell.resource, -self:resolveRaw(spell.resource, spell.resourceCost))
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
        self:deltaResourceAmount(spell.resource, -self:resolveRaw(spell.resource, spell.resourceCost))
    end

    for order, effect in ipairs(spell.effects) do
        print("Passive cast effect:", effect)
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

    --1
    if spell.resourceCost then
        local resourceAmount = self:getResourceAmount(spell.resource)
        local resourceCost = self:resolveRaw(spell.resource, spell.resourceCost)
        if resourceAmount < resourceCost then
            return false, "Not enough " .. ResourceNames[spell.resource]
        end
    end

    --2
    if spell.range then
        local distance = target:distanceFrom(self.location)
        if distance > spell.range then
            return false, "Target out of range"
        end
    end


end

ResourceUnit.cast = function(self, spell, target, location)
    local casttype = spell.castType
    local spellidx = spell.index --To avoid an error on the client

    local target = target or self.target
    local location = location or self.location

    local queriedAuras = {}
    --Check for cast type modifiers from auras
    --For example some passive procs will cause auras that turn some spells into instant casts.
    for _, aura in ipairs(self.auras.noproxy) do
        if aura.aura.modCastType then
            local thisSpellMod = aura.aura.modCastType[spellidx]
            if thisSpellMod then
                casttype = thisSpellMod
                if aura.aura.onQuery then
                    table.insert(queriedAuras, aura)
                end
                break
            end
        end
    end

    if not casttype then
        warn("No cast type for spell " .. spell.name)
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
        assert(target, "No target for any spell")
    else
        error("Unknown target type " .. tostring(spell.targetType))
    end

    ({
        [CastType.Instant] = ResourceUnit.instantCast,
        [CastType.Channeled] = ResourceUnit.channelCast,
        [CastType.Casting]    = ResourceUnit.hardCast,
        [CastType.Passive] = ResourceUnit.passiveCast,
    })[casttype](self, spell, target, location)

    --Dont query auras if cast fails or errors
    for _, aura in ipairs(queriedAuras) do
        aura.aura.onQuery(aura.aura, self, spell, target, location)
    end

    return true
end

ResourceUnit.wantToCast = function(self, spell) --On user input, on npc logic
    local canCast, reason = self:canCast(spell)
    if not canCast then
        return false, reason
    end

    return self:cast(spell)
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

ResourceUnit.aggroedUnits = function(self)
    return 0
end

ResourceUnit.isInCombat = function(self)
    return self:aggroedUnits() > 0 or (utctime() - self.lastAggressiveAction) < ResourceUnit.DropCombatFromOwnActionTimeout
end

ResourceUnit.tick = function(self, deltaTime)
    self:regenTick(deltaTime, self:isInCombat())
    self.super.tick(self, deltaTime)
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
    if critChance > 0 then
        local critRoll = math.random()
        if critRoll < critChance then
            return true
        end
    end
    return false
end

return ResourceUnit