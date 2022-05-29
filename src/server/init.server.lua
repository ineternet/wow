local units = require(game.ReplicatedStorage.Common.ResourceUnit)
local items = require(game.ReplicatedStorage.Common.Item)
local const = require(game.ReplicatedStorage.Common.Const)

local char = units.new()

char.charsheet.class = const.Classes.Mage
char.charsheet.spec = const.Specs.Fire
char.charsheet.race = const.Races.Werebeast
char.charsheet.level = 16
char:updateClassResources()
char.primaryResourceAmount = char.primaryResourceMaximum
char.secondaryResourceAmount = char.secondaryResourceMaximum

local stamdagger = items.newOf(const.Items.StamDagger)

local _ = char.charsheet.equipment:swap(const.Slots.MainHand, stamdagger)


print(("Level %d %s %s %s has %d Spell Power. Equipment: "):format(
    char.charsheet.level,
    const.Specs[char.charsheet.spec],
    const.Classes[char.charsheet.class],
    const.Races[char.charsheet.race],
    char.charsheet:spellPower()
))
print("Mana: " .. char.secondaryResourceMaximum)
print(char.charsheet.equipment)

local sg = game:GetService("StarterGui")
local fr = sg.ScreenGui.Frame

fr.Level.Text = "Level " .. char.charsheet.level
fr.Race.Text = "Race: " .. const.Races[char.charsheet.race]
fr.Class.Text = "Class: " .. const.Classes[char.charsheet.class]
fr.Spec.Text = "Specialization: " .. const.Specs[char.charsheet.spec]
fr.Stamina.Text = "Stamina: " .. char.charsheet:stamina()
fr.Intellect.Text = "Intellect: " .. char.charsheet:intellect()
fr.SpellPower.Text = "Spell Power: " .. char.charsheet:spellPower()
fr.MaxPrimary.Text = "Max Primary: " .. char.primaryResourceMaximum .. " (" .. const.Resources[char.primaryResource] .. ")"
fr.MaxSecondary.Text = "Max Secondary: " .. char.secondaryResourceMaximum .. " (" .. const.Resources[char.secondaryResource] .. ")"
fr.Mastery.Text = "Mastery: " .. char.charsheet:mastery()*100 .. "%"

fr.Cast1.Text = "Cast Fireball"
fr.Cast1.Cover.Size = UDim2.new(0, 0, 1, 0)

local enemy = units.new()
enemy.charsheet.class = const.Classes.Warrior
enemy.charsheet.spec = const.Specs.None
enemy.charsheet.race = const.Races.None
enemy.charsheet.level = 14

enemy.primaryResource = const.Resources.Health
enemy.primaryResourceMaximum = 400
enemy.primaryResourceAmount = 400

local charframe = sg.Hud.PlayerFrame
local enemyframe = sg.Hud.UnitFrame

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    fr.EnemyFullDesc.Text = ("Enemy: Level %s"):format(enemy.charsheet.level)
    fr.EnemyHpDesc.Text = ("Health: %d/%d"):format(enemy.primaryResourceAmount, enemy.primaryResourceMaximum)

    local castRatio = (const.utctime() - char.actionBegin) / const.Spells.Fireball.castTime
    castRatio = math.min(1, castRatio)
    fr.Cast1.Cover.Size = UDim2.new(castRatio, 0, 1, 0)

    local pamount = char.primaryResourceAmount
    local pmax = char.primaryResourceMaximum
    local pratio = pamount / pmax
    charframe.PrimaryResourceBar.Fill.Size = UDim2.new(pratio, 0, 1, 0)
    charframe.PrimaryResourceBar.Resource.Text = pamount .. " / " .. pmax
    charframe.PrimaryResourceBar.Resource.Shadow.Text = pamount .. " / " .. pmax

    local pamount = char.secondaryResourceAmount
    local pmax = char.secondaryResourceMaximum
    local pratio = pamount / pmax
    charframe.SecondaryResourceBar.Fill.Size = UDim2.new(pratio, 0, 1, 0)
    charframe.SecondaryResourceBar.Resource.Text = pamount .. " / " .. pmax
    charframe.SecondaryResourceBar.Resource.Shadow.Text = pamount .. " / " .. pmax

    local pamount = enemy.primaryResourceAmount
    local pmax = enemy.primaryResourceMaximum
    local pratio = pamount / pmax
    enemyframe.PrimaryResourceBar.Fill.Size = UDim2.new(pratio, 0, 1, 0)
    enemyframe.PrimaryResourceBar.Resource.Text = pamount .. " / " .. pmax
    enemyframe.PrimaryResourceBar.Resource.Shadow.Text = pamount .. " / " .. pmax
    
    local pamount = enemy.secondaryResourceAmount
    local pmax = enemy.secondaryResourceMaximum
    local pratio = pamount / pmax
    enemyframe.SecondaryResourceBar.Fill.Size = UDim2.new(pratio, 0, 1, 0)
    enemyframe.SecondaryResourceBar.Resource.Text = pamount .. " / " .. pmax
    enemyframe.SecondaryResourceBar.Resource.Shadow.Text = pamount .. " / " .. pmax
end)

print("Targeting enemy.")
char.target = enemy

--task.wait(3)
--fr.Cast1.MouseButton1Down:connect(function()
print("Casting Fireball: ", char:cast(const.Spells.Fireball))
print("Cast will complete in " .. (char.actionEnd - char.actionBegin) .. " seconds.")

--end)
