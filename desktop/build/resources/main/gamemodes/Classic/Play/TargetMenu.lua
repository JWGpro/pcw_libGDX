require "class"
local g = require "Globals"

local u = {}  -- Public.

-- Received
local world
local java
local uistage
local map

-- Battle outcome display elements
local nameStringA
local nameStringB
local outcomeStringA
local outcomeStringB
local defenceStringA
local defenceStringB
local weaponStringA
local weaponStringB


local container
local label
local targetbuttons = {}

-- Permanent on draw
local selunit
local targets
local indirectallowed

-- Mutable
local target
local validweps
local wepindex

local function updateWeapon(wepIndex)
  wepindex = wepIndex
  
  local outcome = selunit:simulateBattle(target, wepindex)
  local weapon = selunit.weps[wepindex]
  local targetwep
  -- Assume the target has a weapon if the attacker took damage. Though this doesn't catch a target with no ammo.
  if selunit.hp > outcome.attackerHP then
    local i = target:validweps(target.pos, selunit, false)[1]
    targetwep = target.weps[i]
  end
  
  nameStringA:setText(selunit.NAME)
  nameStringB:setText(target.NAME)
  outcomeStringA:setText(selunit.hp .. " >> " .. outcome.attackerHP)  --could zero-pad both for consistency
  outcomeStringB:setText(target.hp .. " >> " .. outcome.defenderHP)
  defenceStringA:setText(tostring(map:getDefence(selunit.pos)))  --stringify to ***, or better, iconify
  defenceStringB:setText(tostring(map:getDefence(target.pos)))
  weaponStringA:setText(weapon.NAME .. " (" .. g.AMMOMOD[weapon.AMMOTYPE][target.ARMOUR] .. ")")
  if targetwep then
    weaponStringB:setText(targetwep.NAME .. " (" .. g.AMMOMOD[targetwep.AMMOTYPE][selunit.ARMOUR] .. ")")
  else
    weaponStringB:setText("CANNOT COUNTER")  --could just have died.
  end
  
  -- Show weapon attack range
  map:clearRanges()
  map:displayAttackRange(weapon, selunit.pos)
end

local function updateTarget(newTarget)
  target = newTarget
  validweps = selunit:validweps(selunit.pos, target, indirectallowed)
  
  world:setCamera(map:long(target.pos.x), map:long(target.pos.y))
  --highlight target, uniquely (camera isn't enough)
  
  updateWeapon(validweps[1])
end

local function nextTarget()
  updateTarget(g.cycle(targets, target, 1))
end

local function prevTarget()
  updateTarget(g.cycle(targets, target, -1))
end

local function changeWep()
  updateWeapon(g.cycle(validweps, wepindex, 1))
end

u.TargetMenu = class()
function u.TargetMenu:init(caller, gameScreen, skin, uiStage, theMap)
  world = caller
  java = gameScreen
  uistage = uiStage
  map = theMap
  
  container = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table", {}, {})
  container:setFillParent(true)
  
  -- Battle outcome display
  --red/blue gradients
  local outcomeTable = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table", {}, {})
  nameStringA = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"nameA", skin})
  nameStringB = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"nameB", skin})
  outcomeTable:add(nameStringA)
  outcomeTable:add(nameStringB)
  outcomeTable:row()
  outcomeStringA = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"outA", skin})
  outcomeStringB = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"outB", skin})
  outcomeTable:add(outcomeStringA)
  outcomeTable:add(outcomeStringB)
  outcomeTable:row()
  defenceStringA = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"defA", skin})
  defenceStringB = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"defB", skin})
  outcomeTable:add(defenceStringA)
  outcomeTable:add(defenceStringB)
  outcomeTable:row()
  weaponStringA = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"wepA", skin})
  weaponStringB = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"wepB", skin})
  outcomeTable:add(weaponStringA)
  outcomeTable:add(weaponStringB)
  
  local button1 = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {"Next", skin})
  java:addChangeListener(button1, nextTarget, nil, nil)
  container:add(button1)
  container:add(outcomeTable)
  container:row()
  
  local button2 = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {"Prev", skin})
  java:addChangeListener(button2, prevTarget, nil, nil)
  container:add(button2)
  container:row()
  
  local button3 = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {"Weapon", skin})
  java:addChangeListener(button3, changeWep, nil, nil)
  container:add(button3)
  
  local button4 = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {"Confirm", skin})
  java:addChangeListener(button4, self.confirm, self, nil)
  container:add(button4)
  
  --targets don't change, but can be hit by one or all weapons as selected. important focus is the target, not the weapon.
end

function u.TargetMenu:show(selUnit, targetlist, indirectAllowed)
  --highlight ALL targets; for k,v in pairs(targets) do target:tint('red') end
  selunit = selUnit
  targets = targetlist
  indirectallowed = indirectAllowed
  
  updateTarget(targets[1])
  
  uistage:addActor(container)
end

function u.TargetMenu:confirm()
  world:dispatchAttack(wepindex, target)  -- World knows what happened, so it can set state.
  self:clear()
end

function u.TargetMenu:clear()
  map:clearRanges()
  container:remove()
end

return u