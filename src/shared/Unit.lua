local Global = require(script.Parent.Global)

local Unit = Global.use"Object".inherit"Unit"

Unit.new = Global.Constructor(Unit, {
    
})

Unit.tick = function(self, deltaTime)
    Unit.super.tick(self, deltaTime)
end

return Unit