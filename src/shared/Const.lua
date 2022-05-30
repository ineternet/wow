local const, DefaultItemValues

local function item(idef)
    for k, v in pairs(DefaultItemValues) do
        idef[k] = idef[k] or v

        --Set the metatable to the default MT
        --The default MT covers cases where stats are not defined
        if type(idef[k]) == "table" then
            setmetatable(idef[k], getmetatable(idef[k]))
        end
    end
    setmetatable(idef, {
        __index = function(t, k)
            if k == "id" then
                for i, v in pairs(const.Items) do
                    if v == t then
                        return i
                    end
                end
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

local function enchant(idef)
    for k, v in pairs(DefaultEnchantValues) do
        idef[k] = idef[k] or v

        --Set the metatable to the default MT
        --The default MT covers cases where stats are not defined
        if type(idef[k]) == "table" then
            setmetatable(idef[k], getmetatable(idef[k]))
        end
    end
    setmetatable(idef, {
        __index = function(t, k)
            if k == "id" then
                for i, v in pairs(const.Enchants) do
                    if v == t then
                        return i
                    end
                end
            end
        end,
        __tostring = function(t)
            return ("(EnchantDefintion:%s)"):format(t.name or "unnamed")
        end,
        __concat = function(a, b)
            return tostring(a) .. tostring(b)
        end
    })
    return idef
end

local numIndexMt = {
    __index = function(t, k)
        for idesc, idx in pairs(t) do
            if idx == k then
                return idesc
            end
        end
    end
}

local function bidirectional(tbl)
    return setmetatable(tbl, numIndexMt)
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

    mod = setmetatable({}, {
        __index = function(t, k)
            return 1
        end
    })
}

DefaultEnchantValues = {
    flat = setmetatable({}, {
        __index = function(t, k)
            return 0
        end
    }),

    mod = setmetatable({}, {
        __index = function(t, k)
            return 1
        end
    })
}

const = {
    Resources = bidirectional {
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
    IntegerResources = {
        Icicles = true, --Zero to five
        Favors = true, --Zero to five
        SoulFragments = true, --Zero to six
        ComboPoints = true, --Zero to five
    },
    Classes = bidirectional {
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
    Specs = bidirectional {
        None = 0,
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
    Races = bidirectional {
        None = 0,
        Human = 1,
        Voidborn = 2,
        Dwarf = 3,
        Halfelf = 4,
        Werebeast = 5
    },
    UnitDescriptors = bidirectional {
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
    Actions = bidirectional {
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
                --haste = 300,
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
    Enchants = {
        MinorStamina = enchant {
            mod = {
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
    SecondaryRatingConversion = {
        mastery = {
            [0] = 0, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.8399984, 2.975236419, 3.110474438, 3.245712457, 3.380950476, 3.516188495, 3.651426514, 3.786664533, 3.921902552, 4.057140571, 4.19237859, 4.327616609, 4.462854628, 4.598092647, 4.737322892, 4.88209548, 5.032659304, 5.189275662, 5.352218918, 5.521777213, 5.698253213, 5.881964896, 6.073246395, 6.272448877, 6.479941485, 6.696112333, 6.921369552, 7.156142407, 7.400882478, 7.676707786, 7.962812896, 8.259580927, 8.567409279, 8.886710161, 9.217911147, 9.561455743, 9.917803988, 10.28743306, 10.67083793, 11.78114906, 13.00698914, 14.36037908, 15.85459057, 17.50427622, 19.32561328, 21.33646224, 23.55654201, 26.00762324, 35.00000009
        },
        versatility = {
            [0] = 0, 3.091154721, 3.091154721, 3.091154721, 3.091154721, 3.091154721, 3.091154721, 3.091154721, 3.091154721, 3.091154721, 3.091154721, 3.091154721, 3.245712457, 3.400270193, 3.554827929, 3.709385665, 3.863943401, 4.018501137, 4.173058873, 4.327616609, 4.482174345, 4.636732081, 4.791289817, 4.945847553, 5.100405289, 5.254963025, 5.414083305, 5.579537691, 5.751610634, 5.930600757, 6.11682162, 6.310602529, 6.512289386, 6.722245596, 6.940853023, 7.168513002, 7.405647412, 7.65269981, 7.910136631, 8.178448466, 8.458151403, 8.773380327, 9.100357595, 9.439521059, 9.79132489, 10.15624018, 10.5347556, 10.92737799, 11.33463313, 11.75706636, 12.19524335, 13.46417035, 14.86513044, 16.4118618, 18.11953208, 20.00488711, 22.08641518, 24.38452828, 26.92176229, 29.72299799, 40.0000001
        },
        haste = {
            [0] = 0, 2.550202644, 2.550202644, 2.550202644, 2.550202644, 2.550202644, 2.550202644, 2.550202644, 2.550202644, 2.550202644, 2.550202644, 2.550202644, 2.677712777, 2.805222909, 2.932733041, 3.060243173, 3.187753306, 3.315263438, 3.44277357, 3.570283702, 3.697793835, 3.825303967, 3.952814099, 4.080324231, 4.207834363, 4.335344496, 4.466618727, 4.603118595, 4.745078773, 4.892745624, 5.046377837, 5.206247087, 5.372638744, 5.545852617, 5.726203744, 5.914023226, 6.109659115, 6.313477343, 6.525862721, 6.747219984, 6.977974908, 7.23803877, 7.507795016, 7.787604874, 8.077843034, 8.378898152, 8.691173367, 9.015086844, 9.351072331, 9.699579745, 10.06107577, 11.10794054, 12.26373262, 13.53978599, 14.94861396, 16.50403187, 18.22129252, 20.11723583, 22.21045389, 24.52147334, 33.00000009
        },
        crit = {
            [0] = 0, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.704760381, 2.8399984, 2.975236419, 3.110474438, 3.245712457, 3.380950476, 3.516188495, 3.651426514, 3.786664533, 3.921902552, 4.057140571, 4.19237859, 4.327616609, 4.462854628, 4.598092647, 4.737322892, 4.88209548, 5.032659304, 5.189275662, 5.352218918, 5.521777213, 5.698253213, 5.881964896, 6.073246395, 6.272448877, 6.479941485, 6.696112333, 6.921369552, 7.156142407, 7.400882478, 7.676707786, 7.962812896, 8.259580927, 8.567409279, 8.886710161, 9.217911147, 9.561455743, 9.917803988, 10.28743306, 10.67083793, 11.78114906, 13.00698914, 14.36037908, 15.85459057, 17.50427622, 19.32561328, 21.33646224, 23.55654201, 26.00762324, 35.00000009
        },
        avoidance = {
            [0] = 0, 1.081904152, 1.081904152, 1.081904152, 1.081904152, 1.081904152, 1.081904152, 1.081904152, 1.081904152, 1.081904152, 1.081904152, 1.081904152, 1.13599936, 1.190094567, 1.244189775, 1.298284983, 1.35238019, 1.406475398, 1.460570605, 1.514665813, 1.568761021, 1.622856228, 1.676951436, 1.731046644, 1.785141851, 1.839237059, 1.894929157, 1.952838192, 2.013063722, 2.075710265, 2.140887567, 2.208710885, 2.279301285, 2.352785959, 2.429298558, 2.508979551, 2.591976594, 2.678444933, 2.768547821, 2.862456963, 2.960352991, 3.070683114, 3.185125158, 3.303832371, 3.426963712, 3.554684064, 3.687164459, 3.824582297, 3.967121595, 4.114973225, 4.268335174, 4.712459623, 5.202795655, 5.744151632, 6.341836227, 7.001710488, 7.730245312, 8.534584897, 9.422616802, 10.4030493, 14.00000004
        },
        leech = {
            [0] = 0, 1.622856228, 1.622856228, 1.622856228, 1.622856228, 1.622856228, 1.622856228, 1.622856228, 1.622856228, 1.622856228, 1.622856228, 1.622856228, 1.70399904, 1.785141851, 1.866284663, 1.947427474, 2.028570285, 2.109713097, 2.190855908, 2.27199872, 2.353141531, 2.434284342, 2.515427154, 2.596569965, 2.677712777, 2.758855588, 2.842393735, 2.929257288, 3.019595583, 3.113565397, 3.211331351, 3.313066328, 3.418951928, 3.529178938, 3.643947837, 3.763469326, 3.887964891, 4.0176674, 4.152821731, 4.293685444, 4.440529487, 4.606024672, 4.777687737, 4.955748556, 5.140445567, 5.332026097, 5.530746688, 5.736873446, 5.950682393, 6.172459837, 6.40250276, 7.068689434, 7.804193483, 8.616227447, 9.51275434, 10.50256573, 11.59536797, 12.80187735, 14.1339252, 15.60457394, 21.00000006 
        },
        speed = {
            [0] = 0, 0.77278868, 0.77278868, 0.77278868, 0.77278868, 0.77278868, 0.77278868, 0.77278868, 0.77278868, 0.77278868, 0.77278868, 0.77278868, 0.811428114, 0.850067548, 0.888706982, 0.927346416, 0.96598585, 1.004625284, 1.043264718, 1.081904152, 1.120543586, 1.15918302, 1.197822454, 1.236461888, 1.275101322, 1.313740756, 1.353520826, 1.394884423, 1.437902658, 1.482650189, 1.529205405, 1.577650632, 1.628072347, 1.680561399, 1.735213256, 1.79212825, 1.851411853, 1.913174952, 1.977534158, 2.044612116, 2.114537851, 2.193345082, 2.275089399, 2.359880265, 2.447831223, 2.539060046, 2.633688899, 2.731844498, 2.833658282, 2.939266589, 3.048810838, 3.366042588, 3.716282611, 4.102965451, 4.529883019, 5.001221777, 5.521603794, 6.096132069, 6.730440573, 7.430749497, 10.00000003
        },
        dodge = {
            [0] = 0, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.164569645, 3.315263438, 3.46595723, 3.616651023, 3.767344816, 3.918038608, 4.068732401, 4.219426194, 4.370119986, 4.520813779, 4.671507572, 4.822201364, 4.972895157, 5.123588949, 5.278731223, 5.440049249, 5.607820368, 5.782335738, 5.96390108, 6.152837466, 6.349482151, 6.554189456, 6.767331697, 6.989300177, 7.220506227, 7.461382314, 7.712383215, 7.973987254, 8.246697618, 8.554045819, 8.872848655, 9.203533033, 9.546541768, 9.90233418, 10.27138671, 10.65419354, 11.0512673, 11.4631397, 11.89036227, 13.12756609, 14.49350218, 16.00156526, 17.66654377, 19.50476493, 21.5342548, 23.77491507, 26.24871824, 28.97992304, 39.0000001
        },
        parry = {
            [0] = 0, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.013875853, 3.164569645, 3.315263438, 3.46595723, 3.616651023, 3.767344816, 3.918038608, 4.068732401, 4.219426194, 4.370119986, 4.520813779, 4.671507572, 4.822201364, 4.972895157, 5.123588949, 5.278731223, 5.440049249, 5.607820368, 5.782335738, 5.96390108, 6.152837466, 6.349482151, 6.554189456, 6.767331697, 6.989300177, 7.220506227, 7.461382314, 7.712383215, 7.973987254, 8.246697618, 8.554045819, 8.872848655, 9.203533033, 9.546541768, 9.90233418, 10.27138671, 10.65419354, 11.0512673, 11.4631397, 11.89036227, 13.12756609, 14.49350218, 16.00156526, 17.66654377, 19.50476493, 21.5342548, 23.77491507, 26.24871824, 28.97992304, 39.0000001
        },
    },
    BaseMana = {
        [0] = 0, 52, 54, 57, 60, 62, 66, 69, 72, 76, 80, 86, 93, 101, 110, 119, 129, 140, 152, 165, 178, 193, 210, 227, 246, 267, 289, 314, 340, 369, 400, 433, 469, 509, 551, 598, 648, 702, 761, 825, 894, 969, 1050, 1138, 1234, 1337, 1449, 1571, 1702, 1845, 2000, 2349, 2759, 3241, 3807, 4472, 5253, 6170, 7247, 8513, 10000
    },
    CastType = {
        Instant = 0,
        Casting = 1,
        Channeled = 2,
    },
    TargetType = {
        Self = 0,
        Enemy = 1,
        Friendly = 2,
        Any = 3,
        Party = 4,
        Area = 5,
    },
    Schools = {
        Physical = 0,
        Holy = 1,
        Fire = 2,
        Nature = 3,
        Frost = 4,
        Shadow = 5,
        Arcane = 6,

        Radiant = 7, --Fire + Holy
        Astral = 8, --Arcane + Nature
        Divine = 9, --Arcane + Holy
        Frostfire = 10, --Fire + Frost
        Shadowflame = 11, --Shadow + Fire
        Consumption = 12, --Shadow + Physical
        Plague = 13, --Nature + Shadow
    },
    GCD = {
        None = 0,
        Standard = 1,
        Reduced = 2,
    },
    Projectiles = {
        Fireball = 0,
    },
    Range = {
        Self = 0,
        Combat = 5,
        Short = 30,
        Long = 40,
    },
    NoResourceRegeneration = function()
        return 0
    end,
    AuraEffectType = bidirectional {
        None = 0,
        Magic = 1,
        Poison = 2,
        Disease = 3,
        Curse = 4,
    }
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

const.GCDTimeout = {
    [const.GCD.None] = 0,
    [const.GCD.Standard] = 1.5,
    [const.GCD.Reduced] = 1,
}

local confirmedNonExistingSpells = {}
const.Spells = setmetatable({

}, {
    __index = function(t, k)
        local rg = rawget(t, k)
        if not rg then
            if not confirmedNonExistingSpells[k] then
                require(script.Parent.Spell)
                rg = rawget(t, k)
                if not rg then
                    confirmedNonExistingSpells[k] = true
                    warn("Error: Spell with index " .. k .. " does not exist. Returning empty spell in the future.")
                    return {}
                end
            else
                rg = {}
            end
        end
        return rg
    end
})

local confirmedNonExistingAuras = {}
const.Auras = setmetatable({

}, {
    __index = function(t, k)
        local rg = rawget(t, k)
        if not rg then
            if not confirmedNonExistingAuras[k] then
                require(script.Parent.Aura)
                rg = rawget(t, k)
                if not rg then
                    confirmedNonExistingAuras[k] = true
                    warn("Error: Aura with index " .. k .. " does not exist. Returning empty aura in the future.")
                    return {}
                end
            else
                rg = {}
            end
        end
        return rg
    end
})

if _VERSION == "Luau" then
    const.utctime = tick
else
    const.utctime = os.time
end

return const
