local Global = require(script.Parent.Global)

local Timer = Global.use"Object".inherit"Timer"

-- Constants



-- Static getters



-- Static functions



-- Constructors

Timer.new = Global.Constructor(Timer, {
    time = 0,
    rate = 1
})

-- Functions and setters

function Timer:SetRate(x)
    assert(type(x) == "number", "rate must be a number")
    assert(x >= 0, "rate must be nonnegative")
    self.rate = x
end

Timer.Equals = Global.ValueEquals



return Timer