require "class"
local g = require "Globals"

local actiontable
local actionbuttons = {}
local buttonlisteners = {}
local w

--This table really only has units in it, plus the UIinit function.
local u = {}

function u.UIinit(world)
  w = world
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
  for act,str in pairs(world.acts) do
    --Create a button for each action.
    local button = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {act, skin})
    actionbuttons[str] = button --Store button.
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
  for i,actionstr in ipairs(self.actions) do
    --Get the button for each action the unit can do.
    local button = actionbuttons[actionstr]
    
    if bool == true then
      --Add to the action table, and add a listener to the button.
      actiontable:add(button)
      local lis = w.gamescreen:addChangeListener(button, self[actionstr], self) --Bind to the appropriate function.
      buttonlisteners[button] = lis --Store the listener for later removal.
      actiontable:row()
    else
      --To undo, clear the listener from the button (not all listeners, or the button stops working), and clear the table (once).
      button:removeListener(buttonlisteners[button])
      if i == 1 then
        actiontable:clearChildren()
      end
    end
  end
end

function Unit:Attack()
  --what if the unit has no weapon? make sure callers check for weapons, or you could check here...
  print(self.cost, self.x)
end

function Unit:Capture()
  print("capture!")
end

function Unit:Wait()
  print("wait!")
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
  self.actions = {[1] = acts.Attack, [2] = acts.Capture, [3] = acts.Wait}
  self.weps = "rifle"
  --weapon classes...see also godot. instantiate so you can manage ammo.

  Unit.init(self, java, bounds, x, y, world)
end

-- Methods for every interaction.
-- Damage calculation methods for each unit, since you have the UAV.

return u