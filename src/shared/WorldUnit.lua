setfenv(1, require(script.Parent.Global))

local WorldUnit = use"Unit".inherit"WorldUnit"

--Unit class that is somewhere in the physical world.

WorldUnit.new = Constructor(WorldUnit, {
    location = Vector3.new(),
    orientation = 0, --Y axis orientation in degrees
})

WorldUnit.distanceFrom = function(self, pointOrUnit)
    if _VERSION ~= "Luau" then
        return 0
    end

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
    if _VERSION ~= "Luau" then
        return true
    end

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

WorldUnit.facing = function(self, pointOrUnit)
    if _VERSION ~= "Luau" then
        return true
    end

    local point
    if type(pointOrUnit) == "table" then
        assertObj(pointOrUnit)
        pointOrUnit:assertIs("WorldUnit")
        point = pointOrUnit.location
    else
        assert(typeof(pointOrUnit) == "Vector3")
        point = pointOrUnit
    end

    local faceframe = CFrame.new(self.location) * CFrame.Angles(0, math.rad(self.orientation), 0)
    local dirframe = CFrame.lookAt(self.location, point)

    return  (dirframe.LookVector - faceframe.LookVector).Magnitude
            <
            math.sqrt(2)
end

WorldUnit.tick = function(self, deltaTime)
    WorldUnit.super.tick(self, deltaTime)
end

return WorldUnit
