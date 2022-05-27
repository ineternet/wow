setfenv(1, require(script.Parent.Global))

local Equipment = use"Object".inherit"Equipment"

--Equipment state

Equipment.new = Constructor(Equipment, {
    slots = {
        Head = nil,
        Neck = nil,
        --Shoulders = nil,
        Back = nil,
        Chest = nil,
        --Waist = nil,
        Hands = nil,
        --Wrist = nil,
        Legs = nil,
        Feet = nil,
        --Tabard = nil,
        Shirt = nil,
        Ring1 = nil,
        Ring2 = nil,
        Trinket1 = nil,
        --Trinket2 = nil,
        MainHand = nil,
        OffHand = nil
    }
})

function Equipment:aggregate(stat)
    local base = 0
    for _, item in pairs(self.slots) do
        if item:def() and item:def().flat and item:def().flat[stat] then
            base = base + item:flat(stat)
        end
    end
    local percentage = 1
    for _, item in pairs(self.slots) do
        if item:def() and item:def().percentage and item:def().percentage[stat] then
            percentage = percentage * item:percentage(stat)
        end
    end
    base = base * percentage
    return base
end

function Equipment:swap(slot, newItem)
    newItem:assertIs("Item")
    local oldItem = self.slots[slot]
    self.slots[slot] = newItem
    return oldItem
end

return Equipment