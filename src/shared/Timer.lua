setfenv(1, require(script.Parent.Global))

local Timer = use"Object".inherit"Timer"

-- Constants



-- Static getters



-- Static functions



-- Constructors

Timer.new = Constructor(Timer, {
    time = 0,
    rate = 1
})

-- Functions and setters

function Timer:SetRate(x)
    self.rate = x
end

Timer.Equals = ValueEquals



return Timer