local const, DefaultItemValues

local function item(idef)
    for k, v in pairs(DefaultItemValues) do
        idef[k] = idef[k] or v
    end
    setmetatable(idef, {
        __index = function(t, k)
            if k == "id" then
                for i, v in pairs(const.Items) do
                    if v == t then
                        return i
                    end
                end
                --return table.find(const.Items, t)
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
    Races = {
        None = 0,
        Human = 1,
        Voidborn = 2,
        Dwarf = 3,
        Halfelf = 4,
        Werebeast = 5
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
                intellect = 4,
                stamina = 5,
                weaponSpeed = 1.4,
                weaponDamage = 4,
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
    Gems = {
        Empty = 0
    },
    Slots = setmetatable({}, {
        __index = function(t, k)
            return k
        end
    }),
    Enchantments = {
        MinorStamina = {
            charsheetPercentageBonus = {
                stamina = 0.01
            }
        }
    },
    PrimaryStatIndex = {
        Strength = 1, Agility = 2, Stamina = 3, Intellect = 4,
        strength = 1, agility = 2, stamina = 3, intellect = 4,
    },
    BasePrimaryStat = function(pstatOrIdx, lvl, class, race)
        if type(pstatOrIdx) == "string" then
            pstatOrIdx = const.PrimaryStatIndex[pstatOrIdx]
        end
        return const.BaseStatsClass[class][lvl][pstatOrIdx] + const.BaseStatsRace[race][pstatOrIdx]
    end,

}

--This relies on the before values

const.BaseStatsRace = { --Str,Sta,Agi,Int
    [0] = { 0, 0, 0, 0 },
    [1] = { 0, 0, 0, 0 },
    [const.Races.None] = { 0, 0, 0, 0 },
    [const.Races.Human] = { 0, 0, 0, 0 },

    [const.Races.Voidborn] = { -3, 1, 0, 2 },
    [const.Races.Dwarf] = { 2, -2, 1, -1 },
    [const.Races.Halfelf] = { -1, -1, 1, 1 },
    [const.Races.Werebeast] = { 2, 1, 0, -3 }
}
const.Durabilities = {
    [const.Slots.Head] = 50,
    [const.Slots.Chest] = 115,
    [const.Slots.Hands] = 40,
    [const.Slots.Legs] = 85,
    [const.Slots.Feet] = 35,
    [const.Slots.MainHand] = 60,
    [const.Slots.OffHand] = 45
}
const.BaseStatsClass = { --Str,Sta,Agi,Int
    [const.Classes.Warrior] = {
        { 18, 12, 19, 12, }, { 20, 14, 21, 14, }, { 22, 16, 23, 16, }, { 24, 18, 25, 18, }, { 26, 20, 27, 20, }, { 28, 22, 29, 22, }, { 30, 24, 31, 24, }, { 32, 26, 33, 26, }, { 34, 28, 35, 28, }, { 36, 30, 37, 30, }, { 38, 32, 39, 32, }, { 40, 34, 41, 34, }, { 42, 36, 43, 36, }, { 44, 38, 45, 38, }, { 46, 40, 47, 40, }, { 48, 42, 49, 42, }, { 50, 44, 51, 44, }, { 52, 46, 53, 46, }, { 54, 48, 55, 48, }, { 56, 50, 57, 50, }, { 58, 52, 59, 52, }, { 60, 54, 61, 54, }, { 62, 56, 63, 56, }, { 64, 58, 65, 58, }, { 66, 60, 67, 60, }, { 68, 62, 69, 62, }, { 70, 64, 71, 64, }, { 72, 66, 73, 66, }, { 74, 68, 75, 67, }, { 76, 70, 77, 69, }, { 78, 72, 79, 71, }, { 80, 74, 81, 73, }, { 82, 76, 83, 75, }, { 84, 78, 85, 77, }, { 86, 80, 87, 79, }, { 88, 82, 89, 81, }, { 90, 84, 91, 83, }, { 92, 86, 93, 85, }, { 94, 88, 95, 87, }, { 96, 90, 97, 89, }, { 98, 92, 99, 91, }, { 100, 94, 101, 93, }, { 102, 96, 103, 95, }, { 104, 98, 105, 97, }, { 106, 100, 107, 99, }, { 108, 102, 109, 101, }, { 110, 104, 111, 103, }, { 112, 106, 113, 105, }, { 114, 108, 115, 107, }, { 155, 110, 148, 109, }, { 176, 124, 171, 122, }, { 197, 138, 194, 136, }, { 218, 151, 217, 149, }, { 239, 165, 240, 163, }, { 261, 178, 267, 176, }, { 298, 205, 296, 202, }, { 335, 231, 325, 228, }, { 372, 257, 354, 254, }, { 409, 284, 383, 280, }, { 450, 310, 414, 306, }, 
    },
    [const.Classes.Mage] = {
        { 8, 12, 19, 18, }, { 9, 14, 21, 20, }, { 10, 16, 23, 22, }, { 12, 18, 25, 24, }, { 13, 20, 27, 26, }, { 14, 22, 29, 28, }, { 16, 24, 31, 30, }, { 17, 26, 33, 32, }, { 18, 28, 35, 34, }, { 19, 30, 37, 36, }, { 21, 32, 39, 38, }, { 22, 34, 41, 40, }, { 23, 36, 43, 42, }, { 25, 38, 45, 44, }, { 26, 40, 47, 46, }, { 27, 42, 49, 48, }, { 28, 44, 51, 50, }, { 30, 46, 53, 52, }, { 31, 48, 55, 54, }, { 32, 50, 57, 56, }, { 33, 52, 59, 58, }, { 35, 54, 61, 60, }, { 36, 56, 63, 62, }, { 37, 58, 65, 64, }, { 39, 60, 67, 66, }, { 40, 62, 69, 68, }, { 41, 64, 71, 70, }, { 42, 66, 73, 72, }, { 44, 67, 75, 74, }, { 45, 69, 77, 76, }, { 46, 71, 79, 78, }, { 48, 73, 81, 80, }, { 49, 75, 83, 82, }, { 50, 77, 85, 84, }, { 51, 79, 87, 86, }, { 53, 81, 89, 88, }, { 54, 83, 91, 90, }, { 55, 85, 93, 92, }, { 56, 87, 95, 94, }, { 58, 89, 97, 96, }, { 59, 91, 99, 98, }, { 60, 93, 101, 100, }, { 62, 95, 103, 102, }, { 63, 97, 105, 104, }, { 64, 99, 107, 106, }, { 65, 101, 109, 108, }, { 67, 103, 111, 110, }, { 68, 105, 113, 112, }, { 69, 107, 115, 114, }, { 70, 109, 148, 155, }, { 79, 122, 171, 176, }, { 88, 136, 194, 197, }, { 97, 149, 217, 218, }, { 105, 163, 240, 239, }, { 114, 176, 267, 261, }, { 131, 202, 296, 298, }, { 148, 228, 325, 335, }, { 164, 254, 354, 372, }, { 181, 280, 383, 409, }, { 198, 306, 414, 450, }, 
    },
    [const.Classes.Hunter] = {
        [1] = { 11, 18, 19, 15, }, [2] = { 13, 20, 21, 17, }, [3] = { 14, 22, 23, 20, }, [4] = { 16, 24, 25, 22, }, [5] = { 18, 26, 27, 24, }, [6] = { 20, 28, 29, 27, }, [7] = { 22, 30, 31, 29, }, [8] = { 23, 32, 33, 31, }, [9] = { 25, 34, 35, 34, }, [10] = { 27, 36, 37, 36, }, [11] = { 29, 38, 39, 39, }, [12] = { 30, 40, 41, 41, }, [13] = { 32, 42, 43, 43, }, [14] = { 34, 44, 45, 46, }, [15] = { 36, 46, 47, 48, }, [16] = { 37, 48, 49, 50, }, [17] = { 39, 50, 51, 53, }, [18] = { 41, 52, 53, 55, }, [19] = { 43, 54, 55, 58, }, [20] = { 45, 56, 57, 60, }, [21] = { 46, 58, 59, 62, }, [22] = { 48, 60, 61, 65, }, [23] = { 50, 62, 63, 67, }, [24] = { 52, 64, 65, 69, }, [25] = { 53, 66, 67, 72, }, [26] = { 55, 68, 69, 74, }, [27] = { 57, 70, 71, 77, }, [28] = { 59, 72, 73, 79, }, [29] = { 60, 74, 75, 81, }, [30] = { 62, 76, 77, 84, }, [31] = { 64, 78, 79, 86, }, [32] = { 66, 80, 81, 89, }, [33] = { 68, 82, 83, 91, }, [34] = { 69, 84, 85, 93, }, [35] = { 71, 86, 87, 96, }, [36] = { 73, 88, 89, 98, }, [37] = { 75, 90, 91, 100, }, [38] = { 76, 92, 93, 103, }, [39] = { 78, 94, 95, 105, }, [40] = { 80, 96, 97, 108, }, [41] = { 82, 98, 99, 110, }, [42] = { 83, 100, 101, 112, }, [43] = { 85, 102, 103, 115, }, [44] = { 87, 104, 105, 117, }, [45] = { 89, 106, 107, 119, }, [46] = { 90, 108, 109, 122, }, [47] = { 92, 110, 111, 124, }, [48] = { 94, 112, 113, 127, }, [49] = { 96, 114, 115, 129, }, [50] = { 98, 155, 148, 131, }, [51] = { 110, 176, 171, 148, }, [52] = { 122, 197, 194, 164, }, [53] = { 134, 218, 217, 180, }, [54] = { 146, 239, 240, 196, }, [55] = { 158, 261, 267, 212, }, [56] = { 181, 298, 296, 244, }, [57] = { 204, 335, 325, 275, }, [58] = { 227, 372, 354, 306, }, [59] = { 251, 409, 383, 338, }, [60] = { 274, 450, 414, 369, }, 
    },
    [const.Classes.Paladin] = {
        [1] = { 18, 6, 19, 18, }, [2] = { 21, 7, 21, 20, }, [3] = { 24, 8, 23, 22, }, [4] = { 27, 9, 25, 24, }, [5] = { 30, 10, 27, 26, }, [6] = { 33, 11, 29, 28, }, [7] = { 35, 12, 31, 30, }, [8] = { 38, 13, 33, 32, }, [9] = { 41, 14, 35, 34, }, [10] = { 44, 15, 37, 36, }, [11] = { 47, 16, 39, 38, }, [12] = { 50, 17, 41, 40, }, [13] = { 53, 18, 43, 42, }, [14] = { 56, 19, 45, 44, }, [15] = { 59, 20, 47, 46, }, [16] = { 62, 21, 49, 48, }, [17] = { 64, 22, 51, 50, }, [18] = { 67, 23, 53, 52, }, [19] = { 70, 25, 55, 54, }, [20] = { 73, 26, 57, 56, }, [21] = { 76, 27, 59, 58, }, [22] = { 79, 28, 61, 60, }, [23] = { 82, 29, 63, 62, }, [24] = { 85, 30, 65, 64, }, [25] = { 88, 31, 67, 66, }, [26] = { 91, 32, 69, 68, }, [27] = { 93, 33, 71, 70, }, [28] = { 96, 34, 73, 72, }, [29] = { 99, 35, 75, 74, }, [30] = { 102, 36, 77, 76, }, [31] = { 105, 37, 79, 78, }, [32] = { 108, 38, 81, 80, }, [33] = { 111, 39, 83, 82, }, [34] = { 114, 40, 85, 84, }, [35] = { 117, 41, 87, 86, }, [36] = { 120, 42, 89, 88, }, [37] = { 122, 43, 91, 90, }, [38] = { 125, 44, 93, 92, }, [39] = { 128, 45, 95, 94, }, [40] = { 131, 46, 97, 96, }, [41] = { 134, 47, 99, 98, }, [42] = { 137, 48, 101, 100, }, [43] = { 140, 49, 103, 102, }, [44] = { 143, 50, 105, 104, }, [45] = { 146, 51, 107, 106, }, [46] = { 149, 52, 109, 108, }, [47] = { 151, 53, 111, 110, }, [48] = { 154, 54, 113, 112, }, [49] = { 157, 55, 115, 114, }, [50] = { 160, 56, 148, 155, }, [51] = { 180, 63, 171, 176, }, [52] = { 200, 70, 194, 197, }, [53] = { 219, 77, 217, 218, }, [54] = { 239, 83, 240, 239, }, [55] = { 259, 90, 267, 261, }, [56] = { 297, 104, 296, 298, }, [57] = { 335, 117, 325, 335, }, [58] = { 374, 130, 354, 372, }, [59] = { 412, 144, 383, 409, }, [60] = { 450, 157, 414, 450, }, 
    },
    [const.Classes.Priest] = {
        [1] = { 10, 15, 19, 18, }, [2] = { 12, 17, 21, 20, }, [3] = { 14, 20, 23, 22, }, [4] = { 15, 22, 25, 24, }, [5] = { 17, 25, 27, 26, }, [6] = { 19, 27, 29, 28, }, [7] = { 21, 29, 31, 30, }, [8] = { 22, 32, 33, 32, }, [9] = { 24, 34, 35, 34, }, [10] = { 26, 37, 37, 36, }, [11] = { 27, 39, 39, 38, }, [12] = { 29, 41, 41, 40, }, [13] = { 31, 44, 43, 42, }, [14] = { 32, 46, 45, 44, }, [15] = { 34, 49, 47, 46, }, [16] = { 36, 51, 49, 48, }, [17] = { 37, 53, 51, 50, }, [18] = { 39, 56, 53, 52, }, [19] = { 41, 58, 55, 54, }, [20] = { 42, 61, 57, 56, }, [21] = { 44, 63, 59, 58, }, [22] = { 46, 65, 61, 60, }, [23] = { 47, 68, 63, 62, }, [24] = { 49, 70, 65, 64, }, [25] = { 51, 73, 67, 66, }, [26] = { 53, 75, 69, 68, }, [27] = { 54, 77, 71, 70, }, [28] = { 56, 80, 73, 72, }, [29] = { 58, 82, 75, 74, }, [30] = { 59, 85, 77, 76, }, [31] = { 61, 87, 79, 78, }, [32] = { 63, 89, 81, 80, }, [33] = { 64, 92, 83, 82, }, [34] = { 66, 94, 85, 84, }, [35] = { 68, 97, 87, 86, }, [36] = { 69, 99, 89, 88, }, [37] = { 71, 102, 91, 90, }, [38] = { 73, 104, 93, 92, }, [39] = { 74, 106, 95, 94, }, [40] = { 76, 109, 97, 96, }, [41] = { 78, 111, 99, 98, }, [42] = { 79, 114, 101, 100, }, [43] = { 81, 116, 103, 102, }, [44] = { 83, 118, 105, 104, }, [45] = { 85, 121, 107, 106, }, [46] = { 86, 123, 109, 108, }, [47] = { 88, 126, 111, 110, }, [48] = { 90, 128, 113, 112, }, [49] = { 91, 130, 115, 114, }, [50] = { 93, 133, 148, 155, }, [51] = { 104, 149, 171, 176, }, [52] = { 116, 165, 194, 197, }, [53] = { 127, 182, 217, 218, }, [54] = { 139, 198, 240, 239, }, [55] = { 150, 214, 267, 261, }, [56] = { 172, 246, 296, 298, }, [57] = { 194, 278, 325, 335, }, [58] = { 217, 310, 354, 372, }, [59] = { 239, 341, 383, 409, }, [60] = { 261, 373, 414, 450, }, 
    },
    [const.Classes.Rogue] = {
        [1] = { 15, 18, 19, 12, }, [2] = { 17, 20, 21, 14, }, [3] = { 20, 22, 23, 16, }, [4] = { 22, 24, 25, 18, }, [5] = { 25, 26, 27, 20, }, [6] = { 27, 28, 29, 22, }, [7] = { 29, 30, 31, 24, }, [8] = { 32, 32, 33, 26, }, [9] = { 34, 34, 35, 28, }, [10] = { 37, 36, 37, 30, }, [11] = { 39, 38, 39, 32, }, [12] = { 41, 40, 41, 34, }, [13] = { 44, 42, 43, 36, }, [14] = { 46, 44, 45, 38, }, [15] = { 49, 46, 47, 40, }, [16] = { 51, 48, 49, 42, }, [17] = { 53, 50, 51, 44, }, [18] = { 56, 52, 53, 46, }, [19] = { 58, 54, 55, 48, }, [20] = { 61, 56, 57, 50, }, [21] = { 63, 58, 59, 52, }, [22] = { 65, 60, 61, 54, }, [23] = { 68, 62, 63, 56, }, [24] = { 70, 64, 65, 58, }, [25] = { 73, 66, 67, 60, }, [26] = { 75, 68, 69, 62, }, [27] = { 77, 70, 71, 64, }, [28] = { 80, 72, 73, 66, }, [29] = { 82, 74, 75, 67, }, [30] = { 85, 76, 77, 69, }, [31] = { 87, 78, 79, 71, }, [32] = { 89, 80, 81, 73, }, [33] = { 92, 82, 83, 75, }, [34] = { 94, 84, 85, 77, }, [35] = { 97, 86, 87, 79, }, [36] = { 99, 88, 89, 81, }, [37] = { 102, 90, 91, 83, }, [38] = { 104, 92, 93, 85, }, [39] = { 106, 94, 95, 87, }, [40] = { 109, 96, 97, 89, }, [41] = { 111, 98, 99, 91, }, [42] = { 114, 100, 101, 93, }, [43] = { 116, 102, 103, 95, }, [44] = { 118, 104, 105, 97, }, [45] = { 121, 106, 107, 99, }, [46] = { 123, 108, 109, 101, }, [47] = { 126, 110, 111, 103, }, [48] = { 128, 112, 113, 105, }, [49] = { 130, 114, 115, 107, }, [50] = { 133, 155, 148, 109, }, [51] = { 149, 176, 171, 122, }, [52] = { 165, 197, 194, 136, }, [53] = { 182, 218, 217, 149, }, [54] = { 198, 239, 240, 163, }, [55] = { 214, 261, 267, 176, }, [56] = { 246, 298, 296, 202, }, [57] = { 278, 335, 325, 228, }, [58] = { 310, 372, 354, 254, }, [59] = { 341, 409, 383, 280, }, [60] = { 373, 450, 414, 306, },
    },
    [const.Classes.Warlock] = {
        [1] = { 7, 14, 19, 18, }, [2] = { 8, 16, 21, 20, }, [3] = { 9, 18, 23, 22, }, [4] = { 10, 21, 25, 24, }, [5] = { 11, 23, 27, 26, }, [6] = { 12, 25, 29, 28, }, [7] = { 13, 27, 31, 30, }, [8] = { 15, 29, 33, 32, }, [9] = { 16, 32, 35, 34, }, [10] = { 17, 34, 37, 36, }, [11] = { 18, 36, 39, 38, }, [12] = { 19, 38, 41, 40, }, [13] = { 20, 41, 43, 42, }, [14] = { 21, 43, 45, 44, }, [15] = { 22, 45, 47, 46, }, [16] = { 23, 47, 49, 48, }, [17] = { 24, 50, 51, 50, }, [18] = { 26, 52, 53, 52, }, [19] = { 27, 54, 55, 54, }, [20] = { 28, 56, 57, 56, }, [21] = { 29, 58, 59, 58, }, [22] = { 30, 61, 61, 60, }, [23] = { 31, 63, 63, 62, }, [24] = { 32, 65, 65, 64, }, [25] = { 33, 67, 67, 66, }, [26] = { 34, 70, 69, 68, }, [27] = { 36, 72, 71, 70, }, [28] = { 37, 74, 73, 72, }, [29] = { 38, 76, 75, 74, }, [30] = { 39, 79, 77, 76, }, [31] = { 40, 81, 79, 78, }, [32] = { 41, 83, 81, 80, }, [33] = { 42, 85, 83, 82, }, [34] = { 43, 87, 85, 84, }, [35] = { 44, 90, 87, 86, }, [36] = { 45, 92, 89, 88, }, [37] = { 47, 94, 91, 90, }, [38] = { 48, 96, 93, 92, }, [39] = { 49, 99, 95, 94, }, [40] = { 50, 101, 97, 96, }, [41] = { 51, 103, 99, 98, }, [42] = { 52, 105, 101, 100, }, [43] = { 53, 108, 103, 102, }, [44] = { 54, 110, 105, 104, }, [45] = { 55, 112, 107, 106, }, [46] = { 56, 114, 109, 108, }, [47] = { 58, 116, 111, 110, }, [48] = { 59, 119, 113, 112, }, [49] = { 60, 121, 115, 114, }, [50] = { 61, 123, 148, 155, }, [51] = { 68, 138, 171, 176, }, [52] = { 76, 153, 194, 197, }, [53] = { 83, 169, 217, 218, }, [54] = { 91, 184, 240, 239, }, [55] = { 98, 199, 267, 261, }, [56] = { 113, 228, 296, 298, }, [57] = { 127, 258, 325, 335, }, [58] = { 142, 287, 354, 372, }, [59] = { 156, 317, 383, 409, }, [60] = { 171, 346, 414, 450, },
    },
    [const.Classes.Druid] = {
        [1] = { 8, 18, 19, 18, }, [2] = { 9, 21, 21, 20, }, [3] = { 10, 24, 23, 22, }, [4] = { 11, 27, 25, 24, }, [5] = { 13, 30, 27, 26, }, [6] = { 14, 33, 29, 28, }, [7] = { 15, 35, 31, 30, }, [8] = { 16, 38, 33, 32, }, [9] = { 18, 41, 35, 34, }, [10] = { 19, 44, 37, 36, }, [11] = { 20, 47, 39, 38, }, [12] = { 21, 50, 41, 40, }, [13] = { 23, 53, 43, 42, }, [14] = { 24, 56, 45, 44, }, [15] = { 25, 59, 47, 46, }, [16] = { 26, 62,49, 48, }, [17] = { 28, 64, 51, 50, }, [18] = { 29, 67, 53, 52, }, [19] = { 30, 70, 55, 54, }, [20] = { 31, 73, 57, 56, }, [21] = { 33, 76, 59, 58, }, [22] = { 34, 79, 61, 60, }, [23] = { 35, 82, 63, 62, }, [24] = { 36, 85, 65, 64, }, [25] = { 38, 88, 67, 66, }, [26] = { 39, 91, 69, 68, }, [27] = { 40, 93, 71, 70, }, [28] = { 41, 96, 73, 72, }, [29] = { 43, 99, 75, 74, }, [30] = { 44, 102, 77, 76, }, [31] = { 45, 105, 79, 78, }, [32] = { 46, 108, 81, 80, }, [33] = { 48, 111, 83, 82, }, [34] = { 49, 114, 85, 84, }, [35] = { 50, 117, 87, 86, }, [36] = { 51, 120, 89, 88, }, [37] = { 53, 122, 91, 90, }, [38] = { 54, 125, 93, 92, }, [39] = { 55, 128, 95, 94, }, [40] = { 56, 131, 97, 96, }, [41] = { 58, 134, 99, 98, }, [42] = { 59, 137, 101, 100, }, [43] = { 60, 140, 103, 102, }, [44] = { 61, 143, 105, 104, }, [45] = { 62, 146, 107, 106, }, [46] = { 64, 149, 109, 108, }, [47] = { 65, 151, 111, 110, }, [48] = { 66, 154, 113, 112, }, [49] = { 67, 157, 115, 114, }, [50] = { 69, 160, 148, 155, }, [51] = { 77, 180, 171, 176, }, [52] = { 86, 200, 194, 197, }, [53] = { 94, 219, 217, 218, }, [54] = { 103, 239, 240, 239, }, [55] = { 111, 259, 267, 261, }, [56] = { 127, 297, 296, 298, }, [57] = { 144, 335, 325, 335, }, [58] = { 160, 374, 354, 372,  }, [59] = { 177, 412, 383, 409, }, [60] = { 193, 450, 414, 450, },
    }
}

return const