setfenv(1, require(script.Parent.Global))

local Unit = use"Object".inherit"Unit"

Unit.new = Constructor(Unit, {
    
})

Unit.tick = function(self, deltaTime)
    self.dirty = true
end

return Unit