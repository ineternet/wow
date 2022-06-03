setfenv(1, require(script.Parent.Global))

local WorldUnit = use"Unit".inherit"WorldUnit"

--Unit class that is somewhere in the physical world.

WorldUnit.new = Constructor(WorldUnit, {
    location = Vector3.new(),
    orientation = 0, --Y axis orientation in degrees
    
})

WorldUnit.distanceFrom = function(self, point)
    --TODO: decide if elevation should be included
    
    local roomDistance = true
    if roomDistance then
        return (self.location - point).Magnitude
    else --plane distance
        return Vector3.new(self.location.X - point.X, 0, self.location.Z - point.Z).Magnitude
    end
end

return WorldUnit