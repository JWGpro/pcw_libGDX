require "class"
local g = require "Globals"

local actiontable
local actionbuttons = {}

--This table really only has units in it, plus the UIinit function.
local u = {}

function u.UIinit(world)
  --Create the actions menu for later modification.
  --Reflection is relatively slow, so this sort of thing should be done once at the game's start.
  actiontable = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table", {}, {})
  world.UIstage:addActor(actiontable)
  actiontable:setFillParent(true)
  actiontable:top()
  actiontable:left()
  actiontable:pad(10)
--  world.UIcamera.zoom = world.UIcamera.zoom * 2
  local fh = world.gamescreen:reflect("com.badlogic.gdx.files.FileHandle", {"String"}, {world.extdir .. "PCW/menuskins/Glassy/glassy-ui.json"})
  local skin = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.Skin", {"FileHandle"}, {fh})
  --You need to dispose of this Skin.
  --Highly recommend you investigate the AssetManager.
  --As long as you declared the actions table with integers for keys, ipairs will maintain order while iterating. pairs does not.
  for i,act in ipairs(world.acts) do
    --Create a button for each action.
    local button = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {act, skin})
    world.gamescreen:addChangeListener(button, "printer") --Bind to an appropriate function.
    actionbuttons[act] = button --Store button.
  end
end

local Unit = class()
function Unit:init(java, bounds, x, y, world)
  self.actor = java:addLuaActor(self.sprite, 1.0, bounds)
  --Store the unit list for later access.
  --...Are there going to be multiple references to this when you only need one?
  self.unitlist = world.units
  --Store the unit by coordinates, storing the coordinates for later lookup.
  self.unitlist[x][y] = self
  self.x = x
  self.y = y
  --Place the unit.
  self.actor:setPosition(g.long(x), g.long(y))
  
  self.hp = self.maxhp
  self.fuel = self.maxfuel
end
function Unit:getMoves()
  return self.moves
end
function Unit:getArmour()
  return self.armour
end
function Unit:getWeps()
  return self.weps
end
function Unit:getHP()
  return self.hp
end
function Unit:setHP(x)
  self.hp = x
end
function Unit:getFuel()
  return self.fuel
end
function Unit:setFuel(x)
  self.fuel = x
end
function Unit:attack(enemy)
  --what if the unit has no weapon? make sure callers check for weapons, or you could check here...
end
function Unit:move(x, y)
  --Kill the existing reference and store a new one.
  self.unitlist[self.x][self.y] = nil
  self.unitlist[x][y] = self
  self.x = x
  self.y = y
  --Then move the unit.
  self.actor:setPosition(g.long(x), g.long(y))
end
function Unit:showactions(bool)
  if bool == true then
    --For each action the unit can do, add the corresponding button to the action table.
    for i,action in pairs(self.actions) do
      actiontable:add(actionbuttons[action])
      actiontable:row()
    end
  else
    --To undo, just clear the table.
    actiontable:clearChildren()
  end

end

u.Infantry = class(Unit)
function u.Infantry:init(java, bounds, x, y, world)
  self.sprite = "PCW/unit_sprites/Default/inf_red_1.png"
  self.cost = 1000
  self.moves = 3
  self.movetype = nil
  self.maxhp = 100
  self.maxfuel = 99
  self.armour = nil
  local acts = world.acts
  --Should fix this somehow...
  self.actions = {acts[1], acts[2], acts[4]}
  self.weps = "rifle"
  --weapon classes...see also godot. instantiate so you can manage ammo.

  Unit.init(self, java, bounds, x, y, world)
end

-- Methods for every interaction.
-- Damage calculation methods for each unit, since you have the UAV.

return u