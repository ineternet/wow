local const, DefaultItemValues

local function item(idef)
    for k, v in pairs(DefaultItemValues) do
        idef[k] = idef[k] or v
    end
    setmetatable(idef, {
        __index = function(t, k)
            if k == "id" then
                return table.find(const.Items, t)
            end
        end,
        __tostring = function(t)
            return ("(ItemDefintion:%s)"):format(t.name or "unnamed")
        end,
        __concat = function(a, b)
            return tostring(a) .. tostring(b)
        end
    })
    return idef
end

DefaultItemValues = {
    --Which slot this item can be equipped in.
    --"Ring" and "Trinket" for any of those slots, respectively.
    --nil if the item is not equippable in any slot.
    equipSlot = nil,

    --Whether this item will take up both hand slots.
    --true/false if the item is a main-hand.
    --nil in any other case.
    --If this is nil for a main-hand, same behavior as "false" is assumed.
    takeBothHands = nil,

    --The Rarity the item usually appears to be.
    --Special cases may override this within the actual item object.
    defaultRarity = 0,

    flat = setmetatable({}, {
        __index = function(t, k)
            return 0
        end
    }),

    percentage = setmetatable({}, {
        __index = function(t, k)
            return 1
        end
    })
}

const = {
    Resources = {
        None = 0,
        Mana = 1,
        Health = 2,
        Fury = 3,           --Warriors, bears
        Focus = 4,          --Hunters, hunter pets
        Energy = 5,         --Rogues, cats, warlock pets
        Corruption = 6,     --Void(Shadow) priest
        Icicles = 7,        --Frost mage
        Favors = 8,         --Divination(Holy) Paladin
        FelEnergy = 9,      --Affliction warlock
        SoulFragments = 10, --Demonology warlock
        ComboPoints = 11,   --Rogues, cats
    },
    Classes = {
        Classless = 0,
        Warrior = 1,
        Mage = 2,
        Hunter = 3,
        Paladin = 4,
        Priest = 5,
        Rogue = 6,
        Druid = 7,
        Warlock = 8,
    },
    Specs = {
        Protection = 11,
        Fury = 12,
        Fire = 21,
        Frost = 22,
        Marksman = 31,
        Survival = 32,
        Crusader = 41,
        Divination = 42,
        Void = 51,
        Discipline = 52,
        Assassin = 61,
        Combat = 62,
        Guardian = 71,
        Feral = 72,
        Restoration = 73,
        Demonology = 81,
        Affliction = 82,
    },
    UnitDescriptors = {
        Inanimate = 0,
        Humanoid = 1,
        Beast = 2,
        Aberration = 3,
        Demon = 4,
        Elemental = 5,
        Mechanical = 6,
        Apparition = 7,
        Undead = 8,
        Draconic = 9,
    },
    Actions = {
        Idle = 0,
        Swing = 1,
        Cast = 2,
        Channel = 3,
    },
    Items = setmetatable({ --IDs are indices of this table (i.e. auto-increment)
        item {
            name = "NullItem"
        },
        item {
            name = "StamDagger",
            equipSlot = "MainHand",
            flat = {
                stamina = 4
            }
        }
    }, {
        __index = function(t, k)
            for _, item in pairs(t) do
                if rawget(item, "name") == k then
                    return item
                end
            end
        end
    }),
    Rarities = {
        Trash = 0,
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Epic = 4,
        Legendary = 10,
        Mythical = 15,
        Artifact = 20,
        Account = 30,
        Corp = 40
    },
    RarityColors = {
        Trash = Color3.new(.6, .6, .6),
        Common = Color3.new(1, 1, 1),
        Uncommon = Color3.new(0.345098, 0.854901, 0.215686),
        Rare = Color3.new(0.196078, 0.380392, 0.878431),
        Epic = Color3.new(0.635294, 0.149019, 0.733333),
        Legendary = Color3.new(0.972549, 0.588235, 0.011764),
        Mythical = Color3.new(0.905882, 0.054901, 0.054901),
        Artifact = Color3.new(0.968627, 0.862745, 0.568627),
        Account = Color3.new(0.203921, 0.870588, 0.960784),
        Corp = Color3.new(0.203921, 0.870588, 0.960784),
    },
    Durabilities = {
        Head = 50,
        Chest = 115,
        Hands = 40,
        Legs = 85,
        Feet = 35,
        MainHand = 60,
        OffHand = 45
    },
    Gems = {
        Empty = 0
    },
    Enchantments = {
        MinorStamina = {
            charsheetPercentageBonus = {
                stamina = 0.01
            }
        }
    }
}

return const