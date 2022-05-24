setfenv(1, require(script.Parent.Global))

local TargetUnit = use"WorldUnit".inherit"TargetUnit"

TargetUnit.new = Constructor(TargetUnit, {
    display = "",
    target = nil
})

return TargetUnit