setfenv(1, require(script.Parent.Global))

local WorldUnit = use"Unit".inherit"WorldUnit"

--Unit class that is somewhere in the physical world.

WorldUnit.new = Constructor(WorldUnit, {
    location = Vector3.new(),
    orientation = 0, --Y axis orientation in degrees
    
})

return WorldUnit