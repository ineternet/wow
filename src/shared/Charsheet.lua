setfenv(1, require(script.Parent.Global))

local Charsheet = use"Object".inherit"Charsheet"

--Stat def for unit type (paper doll)

Charsheet.new = Constructor(Charsheet, {
    level = 1,

    equipment = use"Equipment".new(),


})

function Charsheet:stamina()
    local level = math.ceil(self.level ^ 1.76)
    local equipmentBase = self.equipment:aggregate("stamina")
    local aura = 0
    local auraPercentage = 1
    
    local base = level + equipmentBase
    base = base * auraPercentage

    return base + aura
end

return Charsheet