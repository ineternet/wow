setfenv(1, require(script.Parent.Global))

local TargetUnit = use"WorldUnit".inherit"TargetUnit"

--Unit class that can target and be targeted.

TargetUnit.new = Constructor(TargetUnit, {
    display = "",
    target = nil
})

return TargetUnit