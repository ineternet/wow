setfenv(1, require(script.Parent.Global))

local ItemDef = use"Object".inherit"ItemDef"

local logicalIncrement = 0
ItemDef.new = Constructor(ItemDef, {
    icon = "rbxassetid://1337",
    name = "",

    --Optional
    --equipSlot = Slots.None
    --takeBothHands = false
    --attacksPerSecond = nil
    --rarityOverride = nil
    --enchant = nil
    --sockets = {}
    --flat = {}
    --mod = {}
}, function(self)
    --Automatically assign id to have a common reference point sides
    logicalIncrement = logicalIncrement + 1
    self.id = logicalIncrement
end)

Items.StamDagger = ItemDef.new()
Items.StamDagger:assign({
    name = "Stamina Dagger",
    equipSlot = Slots.MainHand,
    dualWieldable = true,
    attacksPerSecond = 1.5,
    flat = {
        intellect = 4,
        stamina = 5,
        weaponSpeed = 1.4,
        weaponDamage = 4,
    },
})

Items.HasteRing = ItemDef.new()
Items.HasteRing:assign({
    name = "Haste Ring",
    flat = {
        haste = 30,
    },
    equipSlot = Slots.Ring
})

return ItemDef