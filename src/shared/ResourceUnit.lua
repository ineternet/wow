local ContextActionService = game:GetService("ContextActionService")
setfenv(1, require(script.Parent.Global))

local ResourceUnit = use"TargetUnit".inherit"ResourceUnit"

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

ResourceUnit.inferMaximum = function(forResource, fromSheet)
    if not fromSheet then
        return 0
    end
    return ({
        [Resources.None] = 0,
        [Resources.Mana] = math.ceil(fromSheet.level^2.63477+50),
        [Resources.Health] = fromSheet.stamina * 10,
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
    actionBegin = os.time(),
    actionEnd = os.time(),
})

return ResourceUnit