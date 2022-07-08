setfenv(1, require(script.Parent.Global))

local PlayerUnit = use"ResourceUnit".inherit"PlayerUnit"

--Implements player-specific aspects of a player unit.

PlayerUnit.new = Constructor(PlayerUnit, {
    player = nil, --PlayerDesc for this unit
}, function(self, playerdesc)
    self.player = playerdesc
end)

PlayerUnit.tick = function(self, deltaTime)

    --Class-specific ticks

    --Affliction Warlock: Corruption Fel Energy generation
    if self.charsheet.spec == Specs.Affliction then
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