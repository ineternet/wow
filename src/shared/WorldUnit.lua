setfenv(1, require(script.Parent.Global))

local WorldUnit = use"Unit".inherit"WorldUnit"

--Unit class that is somewhere in the physical world.

WorldUnit.new = Constructor(WorldUnit, {
    location = Vector3.new(),
    orientation = 0, --Y axis orientation in degrees
    
})

WorldUnit.distanceFrom = function(self, pointOrUnit)
    --TODO: decide if elevation should be included
    local point
    if type(pointOrUnit) == "table" then
        assertObj(pointOrUnit)
        pointOrUnit:assertIs("WorldUnit")
        point = pointOrUnit.location
    else
        assert(typeof(pointOrUnit) == "Vector3")
        point = pointOrUnit
    end

    local roomDistance = true
    if roomDistance then
        return (self.location - point).Magnitude
    else --plane distance
        return Vector3.new(self.location.X - point.X, 0, self.location.Z - point.Z).Magnitude
    end
end

WorldUnit.los = function(self, pointOrUnit)
    local point
    if type(pointOrUnit) == "table" then
        assertObj(pointOrUnit)
        pointOrUnit:assertIs("WorldUnit")
        point = pointOrUnit.location
    else
        assert(typeof(pointOrUnit) == "Vector3")
        point = pointOrUnit
    end

    --TODO: implement LOS mechanics
    --problem: simply raycasting won't work as some objects should not break LOS
    --defining this property for every single object is not feasible.
    --suggestion: build a LOS map in the world
    return true
end

local facingInterval = math.rad(180) --How much of a cone is considered "in front" of the unit
WorldUnit.facing = function(self, pointOrUnit)
    local point
    if type(pointOrUnit) == "table" then
        assertObj(pointOrUnit)
        pointOrUnit:assertIs("WorldUnit")
        point = pointOrUnit.location
    else
        assert(typeof(pointOrUnit) == "Vector3")
        point = pointOrUnit
    end

    local relativeOrientation = math.atan2(point.Z - self.location.Z, point.X - self.location.X)
    local face2 = facingInterval / 2
    local fmin = self.orientation - face2
    local fmax = self.orientation + face2

    return relativeOrientation >= fmin and relativeOrientation <= fmax
end

WorldUnit.tick = function(self, deltaTime)
    
    WorldUnit.super.tick(self, deltaTime)
end

return WorldUnit