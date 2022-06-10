setfenv(1, require(script.Parent.Global))

local PlayerUnit = use"ResourceUnit".inherit"PlayerUnit"

--Implements player-specific aspects of a player unit.

PlayerUnit.new = Constructor(PlayerUnit, {
    player = nil, --Player instance
    
    party = nil, -- Ref to party object
}, function(self, player)
    self.player = player
end)



return PlayerUnit