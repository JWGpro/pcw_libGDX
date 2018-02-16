require "class"
local g = require "Globals"

local grid

local u = {}

local Unit = class()
function Unit:init(java, bounds, x, y, world)
  grid = world.grid
  self.actor = java:addLuaActor(self.sprite, 1.0, bounds)
  --Store the unit reference twice:
  -- once by coordinates, enabling direct lookup in the existing 2D array, and again in a simple list for iteration.
  grid[x][y].unit = self
  table.insert(world.units, self)
  --Store the coordinates as well.
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
--takeDamage(x)
--heal(x)
function Unit:getFuel()
  return self.fuel
end
function Unit:resupply()
  self.fuel = self.maxfuel
  for i,wep in pairs(self.weps) do
    wep.ammo = wep.maxammo
  end
end
function Unit:burnfuel(x)
  self.fuel = self.fuel - x
end
function Unit:move(x, y)
  --Kill the existing reference and store a new one.
  grid[self.x][self.y].unit = nil
  grid[x][y].unit = self
  self.x = x
  self.y = y
  --Then move the unit.
  self.actor:setPosition(g.long(x), g.long(y))
end

local wep = {}

local Weapon = class()
function Weapon:init()
  --Default constructor for a typical direct fire weapon.
  --Weapons that have no ammo can actually be static.
  --Actually, wouldn't that make most of these (except for ammo) static variables or something? So how would I do that?
  self.direct = true
  self.minrange = 1
  self.maxrange = 1
  --name
  --damage
  --dtype
  --maxammo
  self.ammo = self.maxammo
end
function Weapon:fire()
  self.ammo = self.ammo - 1
end
wep.Rifle = class(Weapon)
function wep.Rifle:init()
  self.name = "Rifle"
  self.damage = 60
  self.dtype = "rifle"
  self.maxammo = nil
  Weapon.init(self)
--  self.direct = false
--  self.minrange = 3
--  self.maxrange = 5
end

wep.Missile = class(Weapon)
function wep.Missile:init()
  self.name = "Missile"
  self.damage = 100
  self.dtype = "missile"
  self.maxammo = 9
  Weapon.init(self)
  self.direct = false
  self.minrange = 3
  self.maxrange = 5
end

u.Infantry = class(Unit)
function u.Infantry:init(java, bounds, x, y, world)
  self.sprite = "PCW/unit_sprites/Default/inf_red_1.png"
  self.cost = 1000
  self.moves = 9
  self.movetype = nil
  self.maxhp = 100
  self.maxfuel = 99
  self.armour = nil
  local acts = world.acts
  self.actions = {[1] = acts.Attack, [2] = acts.Capture, [3] = acts.Wait}
  self.weps = {[1] = wep.Rifle()}

  Unit.init(self, java, bounds, x, y, world)
end

-- Methods for every interaction.
-- Damage calculation methods for each unit, since you have the UAV.

return u