setfenv(1, require(script.Parent.Global))

local TalentTree = use"Object".inherit"TalentTree"

--Represents the talents a player has selected.

local classcommon = {
    warrior25 = {
        [TalentChoice.Left] = Spells.Spell,
        [TalentChoice.Middle] = Spells.Spell,
        [TalentChoice.Right] = Spells.Spell,
    }
}

TalentTree.SpecTalentTrees = {
    [Classes.Warrior] = {
        [Specs.Protection] = {
            [TalentTier.Level10] = {
                [TalentChoice.Left] = Spells.ImprovedBlock,
                [TalentChoice.Middle] = Spells.ImprovedShieldBash,
                [TalentChoice.Right] = Spells.ShieldWall,
            },
            [TalentTier.Level15] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level25] = classcommon.warrior25,
            [TalentTier.Level35] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level45] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level50] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level55] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
        },
        [Specs.Fury] = {
            [TalentTier.Level10] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level15] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level25] = classcommon.warrior25,
            [TalentTier.Level35] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level45] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level50] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level55] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
        },
    },
    [Classes.Warlock] = {
        [Specs.Affliction] = {
            [TalentTier.Level10] = {
                [TalentChoice.Left] = Spells.WritheInAgony,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level15] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level25] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level35] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level45] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level50] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
            [TalentTier.Level55] = {
                [TalentChoice.Left] = Spells.Spell,
                [TalentChoice.Middle] = Spells.Spell,
                [TalentChoice.Right] = Spells.Spell,
            },
        },
    }
}

TalentTree.new = Constructor(TalentTree, {
    [TalentTier.Level10] = TalentChoice.Unassigned,
    [TalentTier.Level15] = TalentChoice.Unassigned,
    [TalentTier.Level25] = TalentChoice.Unassigned,
    [TalentTier.Level35] = TalentChoice.Unassigned,
    [TalentTier.Level45] = TalentChoice.Unassigned,
    [TalentTier.Level50] = TalentChoice.Unassigned,
    [TalentTier.Level55] = TalentChoice.Unassigned,
})

local function getTalentTree(sheet)
    return TalentTree.SpecTalentTrees[sheet.class][sheet.spec]
end

TalentTree.change = function(self, sheet, row, choice)
    if not TalentTier["Level" .. row] then
        return false, "Invalid talent tier Level" .. row
    elseif sheet.level < row then
        return false, "Level too low"
    end
    if self[row] ~= TalentChoice.Unassigned then
        sheet.spellbook:unlearn(getTalentTree(sheet)[row][self[row]])
    end
    self[row] = choice
    if choice ~= TalentChoice.Unassigned then
        sheet.spellbook:learn(getTalentTree(sheet)[row][choice])
    end
    return true, ""
end

return TalentTree