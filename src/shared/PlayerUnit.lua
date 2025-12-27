local Global = require(script.Parent.Global)
local Const = require(script.Parent.Const)
local Spells = Const.Spells
local Auras = Const.Auras
local Resources = Const.Resources

local PlayerUnit = Global.use"ResourceUnit".inherit"PlayerUnit"

--Implements player-specific aspects of a player unit.

PlayerUnit.new = Global.Constructor(PlayerUnit, {
    player = nil, --PlayerDesc for this unit
}, function(self, charsheet, playerdesc)
    self.player = playerdesc
end)

PlayerUnit.tick = function(self, deltaTime)

    --Class-specific ticks

    --Affliction Warlock: Corruption Fel Energy generation
    if self.spellbook:hasSpell(Spells.AfflictionFelEnergy) then
        local regainedFE = 0
        for _, aura in ipairs(self.castAuras.noproxy) do
            if not aura.invalidate and aura.aura.id == Auras.Corruption.id then
                regainedFE = regainedFE + 2 * deltaTime
            end
        end
        self:deltaResourceAmount(Resources.FelEnergy, regainedFE)
    end
    PlayerUnit.super.tick(self, deltaTime)
end

return PlayerUnit