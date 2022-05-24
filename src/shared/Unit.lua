setfenv(1, require(script.Parent.Global))

local Unit = use"Object".inherit"Unit"

Unit.new = Constructor(Unit, {
    
})

return Unit