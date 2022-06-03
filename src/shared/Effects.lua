setfenv(1, require(script.Parent.Global))

local Effect = use"Object".inherit"Effects"

local logicalIncrement = 0
Effect.new = Constructor(Effect, {
    
}, function(self)
    --Automatically assign id to have a common reference point sides
    logicalIncrement = logicalIncrement + 1
    --self.id = logicalIncrement
end)

Effects.Combust = function(worldModel)
    local a = worldModel.Torso.ImpactBase
    a.Combust:Emit(8)
    a.Explode:Emit(20)
    a.Smoke:Emit(15)
end

Effects.ArcaneIntellect = function(worldModel)
    local ie = require(workspace.emojipasta.Intellect)
    ie()
end

return Effect