local units = require(game.ReplicatedStorage.Common.ResourceUnit)
local items = require(game.ReplicatedStorage.Common.Item)
local const = require(game.ReplicatedStorage.Common.Const)
local env = require(game.ReplicatedStorage.Common.Global)

env.Retrieve.OnServerInvoke = function(player, action, arg)
    print("Retrieve: " .. action)
    if action == "getref" then
        print("Retrieving reference: " .. arg, "for player: " .. player.Name)
        return env.__FindByReference(arg)
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
    env.Remote:FireClient(p, "passchar", char)
    --env.restoreSafeObj(char)
end)

game:GetService("ReplicatedStorage").Replicate.OnServerEvent:Connect(function(plr, action, arg)

end)

--const.Retrieve.OnServerInvoke = function()
