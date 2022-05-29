setfenv(1, require(script.Parent.Global))

local Aura = use"Object".inherit"Aura"

local function auraDummy(spell, castingUnit, spellTarget, spellLocation)

end

Aura.createInstance = function(self)
    return {
        aura = self,
        appliedAt = utctime(),
    }
end

Aura.new = Constructor(Aura, {

})

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
})

Auras.PyroblastDot = Aura.new()
Auras.PyroblastDot:assign({
    name = "Pyroblast",
    tooltip = function(sheet)
        local str = "%s Fire damage inflicted every %ssec."
        return str
    end,
    icon = "rbxassetid://1337",
    onTick = function(aura, owner)
        owner:takeDamage(aura.damage, Schools.Fire)
    end,
    baseTickRate = 1.5,
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
    }
})

return Aura