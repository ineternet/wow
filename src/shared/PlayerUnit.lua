setfenv(1, require(script.Parent.Global))

local PlayerUnit = use"ResourceUnit".inherit"PlayerUnit"

--Implements player-specific aspects of a player unit.

PlayerUnit.new = Constructor(PlayerUnit, {
    player = nil, --PlayerDesc for this unit
}, function(self, playerdesc)
    self.player = playerdesc
end)

return PlayerUnit