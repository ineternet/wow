setfenv(1, require(script.Parent.Global))

local TalentTree = use"Object".inherit"TalentTree"

--Represents the talents a player has selected.

TalentTree.ClassTalentTrees = {
    [Classes.Warrior] = {
        level10 = {
            [TalentChoice.Left] = Spells.Spell,
            [TalentChoice.Middle] = Spells.Spell,
            [TalentChoice.Right] = Spells.Spell,
        }
    }
}

TalentTree.new = Constructor(TalentTree, {
    level10 = TalentChoice.Unassigned,
    level15 = TalentChoice.Unassigned,
    level25 = TalentChoice.Unassigned,
    level35 = TalentChoice.Unassigned,
    level45 = TalentChoice.Unassigned,
    level50 = TalentChoice.Unassigned,
    level55 = TalentChoice.Unassigned,
})

TalentTree.change = function(self, sheet, row, choice)
    if row == "level10" and sheet.level < 10 then
        return false, "Level too low"
    elseif row == "level15" and sheet.level < 15 then
        return false, "Level too low"
    elseif row == "level25" and sheet.level < 25 then
        return false, "Level too low"
    elseif row == "level35" and sheet.level < 35 then
        return false, "Level too low"
    elseif row == "level45" and sheet.level < 45 then
        return false, "Level too low"
    elseif row == "level50" and sheet.level < 50 then
        return false, "Level too low"
    elseif row == "level55" and sheet.level < 55 then
        return false, "Level too low"
    end
    self[row] = choice
    return true, ""
end

return TalentTree