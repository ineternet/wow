local units = require(game.ReplicatedStorage.Common.ResourceUnit)
local items = require(game.ReplicatedStorage.Common.Item)
local const = require(game.ReplicatedStorage.Common.Const)
local env = require(game.ReplicatedStorage.Common.Global)

env.Retrieve.OnServerInvoke = function(player, action, arg)
    if action == "getref" then
        local obj = env.__FindByReference(arg).noproxy
        return obj
    end
end

local char = units.new()

char.charsheet.class = const.Classes.Mage
char.charsheet.spec = const.Specs.Fire
char.charsheet.race = const.Races.Werebeast
char.charsheet.level = 16
char:updateClassResources()
char.primaryResourceAmount = char.primaryResourceMaximum
char.secondaryResourceAmount = char.secondaryResourceMaximum

char.charsheet.spellbook:learn(const.Spells.HotStreak)
char.charsheet.spellbook:learn(const.Spells.StartAttack)

local stamdagger = items.newOf(const.Items.StamDagger)

local _ = char.charsheet.equipment:swap(const.Slots.MainHand, stamdagger)

print(("Level %d %s %s %s has %d Spell Power. Equipment: "):format(
    char.charsheet.level,
    const.Specs[char.charsheet.spec],
    const.Classes[char.charsheet.class],
    const.Races[char.charsheet.race],
    char.charsheet:spellPower(char)
))
print("Mana: " .. char.secondaryResourceMaximum)
print(char.charsheet.equipment)

local enemy = units.new()
enemy.charsheet.class = const.Classes.Warrior
enemy.charsheet.spec = const.Specs.None
enemy.charsheet.race = const.Races.None
enemy.charsheet.level = 14
enemy.charsheet.healthRegen = const.NoResourceRegeneration

enemy.primaryResource = const.Resources.Health
enemy.primaryResourceMaximum = 400
enemy.primaryResourceAmount = 400

print("Targeting enemy.")
char.target = env.ref(enemy)

game:GetService("Players").PlayerAdded:Connect(function(p)
    --env.safeObj(char)
    --print(char)
    --game:GetService("ReplicatedStorage"):WaitForChild("Replicate"):FireClient(p, char)
    print("Before pass:", char)
    env.Remote:FireClient(p, "passchar", char.noproxy)
    wait(1)
    --print("Dealing damage now")
    --char:takeDamage(20, env.Schools.Physical)
    --print("Hp after:", enemy.primaryResourceAmount)
    --env.restoreSafeObj(char)

    print("Updating enemy to force update.")
    --enemy.charsheet.level = enemy.charsheet.level + 1
    enemy.display = "Targeted Enemy"
end)

env.Remote.OnServerEvent:Connect(function(plr, action, arg)
    if action == env.Request.CastSpell then
        local spell = env.Spells[arg]
        print("Attempting to cast spell " .. spell.name)
        local suc, msg = char:wantToCast(spell)
        if not suc then
            print("Failed to cast spell: " .. msg)
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
    if char and workspace:FindFirstChild("emojipasta") then
        char.location = workspace.emojipasta.HumanoidRootPart.Position
        char.orientation = workspace.emojipasta.HumanoidRootPart.Orientation.Y
    end
    if enemy and workspace:FindFirstChild("Dummy") then
        enemy.location = workspace.Dummy.Torso.Position
        enemy.orientation = workspace.Dummy.Torso.Orientation.Y
    end
end)

--const.Retrieve.OnServerInvoke = function()
