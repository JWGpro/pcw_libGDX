require "class"
local g = require "Globals"

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
function Unit:showactions()
  --For each action, add button to vertical column. If action is possible, enable the button.
  --Provide access to the Scene2D widgets.
  
  for i,action in pairs(self.actions) do
    print(action)
  end
end

local u = {}

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
  self.actions = {acts.wait, acts.attack, acts.capture}
  self.weps = "rifle"
  --weapon classes...see also godot. instantiate so you can manage ammo.

  Unit.init(self, java, bounds, x, y, world)
end

-- Methods for every interaction.
-- Damage calculation methods for each unit, since you have the UAV.

return u