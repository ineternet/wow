setfenv(1, require(script.Parent.Global))

local WorldUnit = use"Unit".inherit"WorldUnit"

WorldUnit.new = Constructor(WorldUnit, {
    location = CFrame.new()
})

return WorldUnit