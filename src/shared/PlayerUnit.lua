setfenv(1, require(script.Parent.Global))

local PlayerUnit = use"ResourceUnit".inherit"PlayerUnit"

--Implements player-specific aspects of a player unit.

PlayerUnit.new = Constructor(PlayerUnit, {
    player = nil, --Player instance
    
    party = nil, -- Ref to party object

    xp = 0, --TOTAL accumulated XP
}, function(self, player)
    self.player = player
end)

PlayerUnit.gainXp = function(self, xp)
    self.xp = self.xp + xp
    --TODO: level up
end

PlayerUnit.saveToDb = function(self)
    --TODO
end



return PlayerUnit