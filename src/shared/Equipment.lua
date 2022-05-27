setfenv(1, require(script.Parent.Global))

local Equipment = use"Object".inherit"Equipment"

--Equipment state

local iconst = use"Item".newOf
Equipment.new = Constructor(Equipment, {
    slots = {
        Head = iconst("NullItem"),
        Neck = iconst("NullItem"),
        --Shoulders = nil,
        Back = iconst("NullItem"),
        Chest = iconst("NullItem"),
        --Waist = nil,
        Hands = iconst("NullItem"),
        --Wrist = nil,
        Legs = iconst("NullItem"),
        Feet = iconst("NullItem"),
        --Tabard = nil,
        Shirt = iconst("NullItem"),
        Ring1 = iconst("NullItem"),
        Ring2 = iconst("NullItem"),
        Trinket1 = iconst("NullItem"),
        --Trinket2 = nil,
        MainHand = iconst("NullItem"),
        OffHand = iconst("NullItem")
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