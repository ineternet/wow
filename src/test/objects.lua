--Environment setup code
---@diagnostic disable-next-line: undefined-global
package.path = "./?/init.lua;" .. package.path

local lemur = require("lemur")
local habitat = lemur.Habitat.new()

local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")
local root = habitat:loadFromFs("src/shared", {
    loadInitModules = true
})
root.Parent = ReplicatedStorage
--End Environment setup code

local units = habitat:require(root.ResourceUnit)
local playerdesc = habitat:require(root.PlayerDesc)
local playerunits = habitat:require(root.PlayerUnit)
local items = habitat:require(root.Item)
local const = habitat:require(root.Const)
local env = habitat:require(root.Global)

local plr = playerdesc.new(nil, "", { --Mock DB entry
    xp = 0,
    talents = {

    },
})

local cs = habitat:require(root.Charsheet).new()
cs.class = const.Classes.Warlock
cs.spec = const.Specs.Affliction
cs.race = const.Races.Werebeast
cs.level = 17

local tu = playerunits.new(nil, cs, plr)
tu:updateClassResources()
tu.primaryResourceAmount = tu.primaryResourceMaximum
tu.secondaryResourceAmount = tu.secondaryResourceMaximum

local ecs = habitat:require(root.Charsheet).new()
ecs.class = const.Classes.Warrior
ecs.spec = const.Specs.None
ecs.race = const.Races.None
ecs.level = 14
ecs.healthRegen = const.NoResourceRegeneration

local enemy = units.new(nil, cs)
enemy.primaryResource = const.Resources.Health
enemy.primaryResourceMaximum = 400
enemy.primaryResourceAmount = 400

tu:targetUnit(enemy)

local stamdagger = items.newOf(const.Items.StamDagger)
local stamdagger2 = items.newOf(const.Items.StamDagger)

local _ = tu.charsheet.equipment:swap(const.Slots.MainHand, stamdagger)
local _ = tu.charsheet.equipment:swap(const.Slots.OffHand, stamdagger2)

print("Stamina:", tu.charsheet:stamina(tu))
print("Enchanting Main Hand with Minor Stamina:", const.Enchants.MinorStamina:applyToItem(stamdagger))
print("Stamina:", tu.charsheet:stamina(tu))

local hastering = items.newOf(const.Items.HasteRing)
local _ = tu.charsheet.equipment:swap(const.Slots.Ring1, hastering)

tu.charsheet.spellbook:learn(const.Spells.Bloodlust)

--env.use"Spell".ApplyAura(nil, enemy, const.Auras.ArcaneIntellect, nil, { duration = 60*60 })
--env.use"Spell".ApplyAura(const.Spells.Corruption, enemy, const.Auras.Corruption, tu, { duration = 60*60 })

--Writhe in Agony
tu.player.talents:change(tu.charsheet, const.TalentTier.Level10, const.TalentChoice.Left)

print("Enemy HP:", enemy.primaryResourceAmount)
print("Fel Energy:", tu.tertiaryResourceAmount)
print("Casting Agony:", tu:wantToCast(const.Spells.Agony))
print("Skipping 2s.")
env.UnreplicatedTimeTravel(2)
print("Casting Bloodlust:", tu:wantToCast(const.Spells.Bloodlust))
print(("Haste: %.1f%%"):format(tu.charsheet:haste(tu)*100))
print("Casting Corruption:", tu:wantToCast(const.Spells.Corruption))
print("Agony has", enemy:findFirstAura(const.Auras.Agony).stacks, " stacks and will remain for:", const.AuraTimer(enemy:findFirstAura(const.Auras.Agony):remainingTime()))
print("Skipping 9s.")
env.UnreplicatedTimeTravel(9)
print("Enemy HP:", enemy.primaryResourceAmount)
print("Agony has", enemy:findFirstAura(const.Auras.Agony).stacks, " stacks and will remain for:", const.AuraTimer(enemy:findFirstAura(const.Auras.Agony):remainingTime()))
print("Casting Agony:", tu:wantToCast(const.Spells.Agony))
print("Agony has", enemy:findFirstAura(const.Auras.Agony).stacks, " stacks and will remain for:", const.AuraTimer(enemy:findFirstAura(const.Auras.Agony):remainingTime()))
print("Fel Energy:", tu.tertiaryResourceAmount)