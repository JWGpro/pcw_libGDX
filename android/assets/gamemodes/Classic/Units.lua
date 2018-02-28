require "class"
local g = require "Globals"
local f = require "commandfuncs"

local java = g.gamescreen
local bounds = g.cellsize
local grid = g.grid
local units = g.teamunits

local statics = {}

local u = {}

local Unit = class()
function Unit:init(x, y, teamID)
  self.actor = java:addLuaActor(self.sprite, 1.0, bounds)
  -- Store the unit reference for direct lookup in a 2D array of the grid.
  grid[x][y].unit = self
  -- Store the unit reference again in a separate list for more direct iteration (required for restoring units each turn).
  table.insert(units[teamID], self)
  self.unitnumber = #units[teamID]
  -- Store the coordinates as well.
  self.startX = x
  self.startY = y
  self.x = self.startX
  self.y = self.startY
  -- Place the unit.
  self.actor:setPosition(g.long(x), g.long(y))
  
  -- Initialise weapons.
  self.weps = {}
  for i,wep in ipairs(self.WEPS) do
    if wep.MAXAMMO then
      self.weps[i] = wep()  -- Instance
    else
      self.weps[i] = wep    -- Static
    end
  end
  self.team = teamID
  self.hp = self.MAXHP
  self.fuel = self.MAXFUEL
  -- Sets maximum and remaining moves.
  self.maxmoves = self:getmoves()
  self.movesleft = self.maxmoves
end
function Unit:getHP()
  return self.MAXHP
end
function Unit:takeDamage(x)
  self.hp = self.hp - x
  if self.hp <= 0 then
    self:die()
  end
end
function Unit:die()
  --what if you die from a counterattack? shouldn't it be startXY?
  grid[self.startX][self.startY].unit = nil
  table.remove(units[self.team], self.unitnumber)
  self.actor:remove()
  --play an anim
  --Lua should GC if no references, so when the World lets go of its target.
  --by the way, Actors shouldn't have their own Sprites because you should be using an AssetManager. so no need to dispose.
end
function Unit:heal(x)
  local newhp = self.hp + x
  if newhp > self.MAXHP then
    self.hp = self.MAXHP
  else
    self.hp = newhp
  end
end
function Unit:getFuel()
  return self.fuel
end
function Unit:resupply()
  self.fuel = self.MAXFUEL
  for i,wep in ipairs(self.weps) do
    wep.ammo = wep.MAXAMMO
  end
end
function Unit:burnfuel(x)
  self.fuel = self.fuel - x
end
function Unit:wait()
  self:burnfuel(self.maxmoves - self.movesleft)
  self.movesleft = 0  -- Acts as a "this unit has been ordered" flag.
  self.actor:tint(0x7f7f7fff)
  
  -- Kill the old reference and store a new one, and store the new starting coords for the next turn.
  -- If self.startX is nil then it means the unit is waiting after a disembark. If you killed a reference, it'd be of the unit it came off of.
  if not self.boardnumber then
    grid[self.startX][self.startY].unit = nil
  end
  self.startX = self.x
  self.startY = self.y
  grid[self.startX][self.startY].unit = self
end
function Unit:board(destunit)
  -- Similar to wait().
  
  self:burnfuel(self.maxmoves - self.movesleft)
  -- We want to retain movesleft, and there's no need to tint.
  
  -- Kill the old reference, but don't store a new one, because you're off the grid.
  grid[self.startX][self.startY].unit = nil
  self.startX = nil
  self.startY = nil
  self.x = nil
  self.y = nil
  
  self.actor:hide()
  table.insert(destunit.boardedunits, self)
  self.boardnumber = #destunit.boardedunits
  --inf appears behind APC when it should be on top. don't really give a fock right now but still. selunit should be always on top.
  -- cackhanded way of doing that would be to hide()show() upon selection.
  --boarding animation(lightshafts)/noise, show boarded icon on APC
end
function Unit:disembark(world, destunit)
  self.actor:show()
  -- The purpose of startX and startY is to snap you back to your original location on the grid when you want to undo a move.
  -- When you want to undo a disembark-move, you will end up ON the APC (not back inside it unless you cancel again), but not on the grid.
  self.startX = destunit.x
  self.startY = destunit.y
  self.x = self.startX
  self.y = self.startY
  self.actor:setPosition(g.long(self.x), g.long(self.y))
  table.remove(destunit.boardedunits, self.boardnumber)  --here's a bug for u. inf1 boards and inf2 boards. inf1 leaves. inf2 is now in 1.
  --so u need to rethink this system and rename the entry u use to check for boarded units while ur at it.
  --same is true of die(), or any table.remove().
  self.boardnumber = nil
  -- Now select the unit so it can move...
  f.select(world, self)
end
function Unit:restore()
  -- Restore moves and reset tint.
  self.maxmoves = self:getmoves()
  self.movesleft = self.maxmoves
  self.actor:resetTint()
  --you could burn fuel here for aircraft (or wait until your next turn like AW to allow 0-fuel autosupplies and block/counter).
end
function Unit:getmoves()
  if self.fuel > self.MOVERANGE then
    return self.MOVERANGE
  else
    return self.fuel
  end
end
function Unit:move(x, y)
  self.movesleft = self.movesleft - g.mandist(self.x - x, self.x - y)
  -- Store new (temporary) coordinates.
  self.x = x
  self.y = y
  -- Then move the unit with an animation. (At the moment there is no animation.)
  --animatemove
  self.actor:setPosition(g.long(x), g.long(y))
end
function Unit:snapback()
  self.movesleft = self.maxmoves
  self.x = self.startX
  self.y = self.startY
  self.actor:setPosition(g.long(self.x), g.long(self.y))
end
function Unit:battle(target, wepindex, defstars)
  -- Round up HP to ints from 1-10, then convert to percentage strengths for battle calculation.
  local atkstrength = math.ceil((self.hp / self.MAXHP) * 10) / 10
  local defstrength = math.ceil((target.hp / target.MAXHP) * 10) / 10
  local weapon = self.weps[wepindex]
  -- Look up the modifier for the ammo type on the defender's armour.
  local armourpenalty = g.ammomod[weapon.AMMOTYPE][target.ARMOUR]
  -- Terrain defences subtract 10% damage for each star, but the effect is proportional to the defender's strength.
  local terrainpenalty = (1 - (0.1 * defstars * defstrength))
  
  local damage = atkstrength * weapon.DAMAGE * armourpenalty * terrainpenalty
  
  weapon:fire()
  target:takeDamage(damage)
  print(target.team, target.NAME, target.hp)
end
function Unit:validweps(target, indirectallowed)
  local weplist = {}
  local dist = g.mandist(self.x - target.x, self.y - target.y)
  
  for i,wep in ipairs(self.weps) do
    -- Conditions:
    --  Non-zero ammo. This means that both weapons with remaining ammo AND nil ammo (infinite) are allowed.
    --  Target is within minimum and maximum ranges.
    --  Target armour type is hittable with this weapon damage type.
    --  Weapon is direct, or indirect weapons are allowed.
    if (wep.ammo ~= 0)
    and (wep.MINRANGE <= dist and dist <= wep.MAXRANGE)
    and (g.ammomod[wep.AMMOTYPE][target.ARMOUR])
    and (wep.DIRECT or indirectallowed) then
      table.insert(weplist, i)
    end
  end
  
  return weplist
end

local wep = {}

local Weapon = class()
function Weapon:init()
  -- Static weapons (with infinite ammo) will never be constructed or call this.
  -- At the moment, there's actually nothing for a static weapon to inherit from Weapon. The fields and methods are useless.
  -- So they could just be tables right now.
  self.ammo = self.MAXAMMO
end
function Weapon:fire()
  if self.MAXAMMO then
    self.ammo = self.ammo - 1
  end
end

wep.Rifle = class(Weapon)
statics = {
  NAME = "Rifle",
  DAMAGE = 60,
  AMMOTYPE = g.ammotypes.RifleRound,
  MAXAMMO = nil,
  DIRECT = true,
  MINRANGE = 1,
  MAXRANGE = 1
}
g.addPairs(wep.Rifle, statics)

wep.Missile = class(Weapon)
statics = {
  NAME = "Missile",
  DAMAGE = 100,
  AMMOTYPE = "missile",
  MAXAMMO = 9,
  DIRECT = false,
  MINRANGE = 3,
  MAXRANGE = 5
}
g.addPairs(wep.Missile, statics)
function wep.Missile:init()
  Weapon.init(self)
end

u.Infantry = class(Unit)
statics = {
  NAME = "Infantry",
  COST = 1000,
  MOVERANGE = 3,
  MOVETYPE = g.movetypes.Infantry,
  MAXHP = 100,
  MAXFUEL = 99,
  ARMOUR = g.armours.Vest,
  WEPS = {[1] = wep.Rifle}
  --CAPTURESTRENGTH = 1.0
}
g.addPairs(u.Infantry, statics)
function u.Infantry:init(x, y, teamID)
  self.sprite = "PCW/unit_sprites/Default/inf_red_1.png"
  if teamID == g.teams.Blue then
    self.sprite = "PCW/unit_sprites/Default/inf_blue_1.png"
  end

  Unit.init(self, x, y, teamID)
end

u.APC = class(Unit)
statics = {
  NAME = "APC",
  COST = 4000,
  MOVERANGE = 6,
  MOVETYPE = g.movetypes.Track,
  MAXHP = 100,
  MAXFUEL = 99,
  ARMOUR = g.armours.HVeh,
  WEPS = {},
  
  BOARDABLE = g.set{u.Infantry.NAME},
  BOARDCAP = 1
}
g.addPairs(u.APC, statics)
function u.APC:init(x, y, teamID)
  --Ideally you will use ipairs on this array.
  self.boardedunits = {}
  self.sprite = "PCW/unit_sprites/Default/apc_red.png"

  Unit.init(self, x, y, teamID)
end
function u.APC:die()
  -- Kill everything on board before dying.
  --But...references? See what's changed in board()...
  for k,unit in pairs(self.boardedunits) do
    unit:die()
  end
  Unit.die(self)
end
--override u.APC:wait() to modify everything inside.
--you need to do this for each boardable - maybe you can do it programmatically. "if self.BOARDABLE then waitall" in wait() i guess.
--well no because of grid refs and shit. ughhhhhhhhhhh.

statics = nil

return u