require "class"
local g = require "Globals"

local java
local map
local teamunits

-- This doesn't hold anything permanently. It's used to help push statics into classes, then wiped.
local statics = {}

local u = {}  -- Public.

function u.init(gameScreen, theMap, teamUnits)
  java = gameScreen
  map = theMap
  teamunits = teamUnits
end

local Unit = class()
function Unit:init(x, y, teamID)
  self.actor = java:addLuaActor(self.sprite, 1.0)
  -- Store the coordinates. These are grabbed by functions in Map and World.
  self.pos = Vector2(x, y)
  -- Place the unit.
  self:placeActor(self.pos)
  
  -- Store the unit reference for direct lookup in a 2D array of the grid.
  map:storeUnitRef(self)
  -- Store the unit reference again in a separate list for more direct iteration (required for restoring units each turn).
  table.insert(teamunits[teamID], self)
  self.unitnumber = #teamunits[teamID]
  
  -- Initialise weapons.
  self.weps = {}
  for i,wep in ipairs(self.WEPS) do
    if wep:isStatic() then
      self.weps[i] = wep    -- Static
    else
      self.weps[i] = wep()  -- Instance
    end
  end
  self.team = teamID
  self.hp = self.MAXHP
  self.fuel = self.MAXFUEL
  self:restore()  -- Predeployed units will be movable. Deployed units should not, as DeployMenu will tell them to wait().
  self.isBoarded = false
end
function Unit:placeActor(vector)
  self.actor:setPosition(map:long(vector.x), map:long(vector.y))
end
function Unit:getStrength()
  -- Round up HP to ints from 1-10 for display or strength calculations (attack/capture...).
  return math.ceil((self.hp / self.MAXHP) * 10)
end
function Unit:isWounded()
  return self.hp ~= self.MAXHP
end
function Unit:takeDamage(x)
  self.hp = self.hp - x
  if self.hp <= 0 then
    self:die()
  end
end
function Unit:die()
  --what if you die from a counterattack? shouldn't it be startXY?
  --UMM LOL
  --two possibilities: attacker moved and killed its own ref, and has no ref if it dies. but this call will kill ref at its destination. that's ok...
  --or: defender did not move and needs to kill its own ref.
  if not self.isBoarded then
    map:killUnitRef(self)
    self.actor:remove()
  end
  table.remove(teamunits[self.team], self.unitnumber)
  --play an anim
  --Lua should GC if no references, so when the World lets go of its target.
  --by the way, Actors shouldn't have their own Sprites because you should be using an AssetManager. so no need to dispose.
  
  --can't ever GC units because they are stored in the replay.
end
function Unit:heal(x)
  --if you're dead, then live again! (due to a replay rewind)
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
function Unit:setFuel(x)
  self.fuel = x
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
function Unit:addfuel(x)
  local newfuel = self.fuel + x
  if newfuel > self.MAXFUEL then
    self.fuel = self.MAXFUEL
  else
    self.fuel = newfuel
  end
end
function Unit:movesused()
  return (self.maxmoves - self.movesleft)
end
function Unit:wait()
  self.canOrder = false
  self.actor:tint(0x7f7f7fff)  -- Grey
end
function Unit:unwait()
  self.canOrder = true
  self.actor:resetTint()
end
function Unit:restore()
  self.maxmoves = self:getmoves()
  self.movesleft = self.maxmoves
  self:unwait()
  --you could burn fuel here for aircraft (or wait until your next turn like AW to allow 0-fuel autosupplies and block/counter).
end
function Unit:canMove()
  return self.movesleft > 0
end
function Unit:board(transport)
  self.pos = nil
  self.isBoarded = true
  
  self.actor:hide()
  table.insert(transport.boardedunits, self)
  self.boardnumber = #transport.boardedunits
  --inf appears behind APC when it should be on top. don't really give a fock right now but still. selunit should be always on top.
  -- cackhanded way of doing that would be to hide()show() upon selection.
  --boarding animation(lightshafts)/noise, show boarded icon on APC
end
function Unit:disembark(transport)
  self.pos = transport.pos
  self.isBoarded = false
  self:placeActor(self.pos)
  
  self.actor:show()
  table.remove(transport.boardedunits, self.boardnumber)  --here's a bug for u. inf1 boards and inf2 boards. inf1 leaves. inf2 is now in 1.
  --so u need to rethink this system and rename the entry u use to check for boarded units while ur at it.
  --same is true of die(), or any table.remove().
  self.boardnumber = nil
end
function Unit:getmoves()
  if self.fuel > self.MOVERANGE then
    return self.MOVERANGE
  else
    return self.fuel
  end
end
function Unit:move(dest, direction)
  -- Direction should be +1 (forwards) or -1 (backwards). But I guess it could be used as a general cost modifier (e.g. for snow).
  
  -- Do nothing for a zero-move.
  if dest:equals(self.pos) then
    return
  end
  
  -- Get the A* path and cost.
  local astars = map:astar(self, dest)
  
  local path = {}
  local start = self.pos
  local check = map:getVector(dest.x, dest.y)
  -- Recreate the A* path from end to start.
  while not check:equals(start) do
    -- Add the current cell to the path.
    table.insert(path, check)
    -- Get the next cell in the path.
    check = astars.trace[check]
  end
  
  local fuelcost
  
  if direction > 0 then
    -- Forwards: iterate backwards over the path and animate the unit through it.
    for i = #path, 1, -1 do
      local x = map:long(path[i].x)
      local y = map:long(path[i].y)
      local cellcost = map:getCost(self, path[i])  -- The unit will move slower in proportion to the cost of moving into the cell.
      queue(self.actor.moveTo, self.actor, x, y, 0.05 * cellcost)
      queue(blockWhile, self.isMoving, self)  -- Must be queued, as unit won't be moving until the next frame (when queue is accessed).
    end
    fuelcost = direction * astars.cost
  else
    -- Backwards: just snap back. But adjust the fuel cost, as there was a cost to move to the current space, and no cost to move from path[1].
    self:placeActor(dest)
    fuelcost = direction * (astars.cost + map:getCost(self, start) - map:getCost(self, path[1]))
  end
  
  -- Deduct spaces moved, and burn (or add) fuel.
  self.movesleft = self.movesleft - fuelcost
  self:burnfuel(fuelcost)
  
  -- Update coordinates (if possible - handled by the methods themselves).
  map:killUnitRef(self)
  self.pos = dest
  map:storeUnitRef(self)
end
function Unit:isMoving()
  return (self.actor:getActions().size > 0)
end
function Unit:simulateAttack(target, wepindex)
  return g.damageCalc(self.CLASS, self.hp, wepindex, target.CLASS, target.hp, map:getDefence(target.pos))
end
function Unit:attack(target, wepindex)
  local damage = self:simulateAttack(target, wepindex)
  
  local weapon = self.weps[wepindex]
  weapon:fire()
  
  local targetIsAlive = target.hp > damage
  target:takeDamage(damage)
  print(target.team, target.NAME, target.hp)
  return targetIsAlive
end
function Unit:simulateBattle(target, wepindex)
  local attackerDamage = self:simulateAttack(target, wepindex)
  local targethp = target.hp - attackerDamage
  local defenderDamage = 0
  -- Check if the target would be alive. They can counterattack with the first available weapon.
  if targethp > 0 then
    local counterweps = target:validweps(target.pos, self, false)
    if #counterweps > 0 then
      defenderDamage = g.damageCalc(target.CLASS, targethp, 1, self.CLASS, self.hp, map:getDefence(self.pos))
    end
  end
  
  return {attackerHP = self.hp - defenderDamage, defenderHP = targethp}
end
function Unit:battle(target, wepindex)
  local targetIsAlive = self:attack(target, wepindex)
  
  -- Check if the target is alive. They will counterattack with the first available weapon.
  --feels really bad and ***REMOVED*** that i check for the target being alive in two different ways. this whole thing is just a fucking mess.
  if targetIsAlive then
    local counterweps = target:validweps(target.pos, self, false)
    if #counterweps > 0 then
      target:attack(self, 1)
    end
  end
  
end
function Unit:validweps(position, target, indirectallowed)
  local weplist = {}
  local dist = position:mandist(target.pos)
  
  for i,wep in ipairs(self.weps) do
    -- Conditions:
    -- Non-zero ammo. This means that both weapons with remaining ammo AND nil ammo (infinite) are allowed.
    if (wep.ammo ~= 0)
    -- Target is within minimum and maximum ranges.
    and (wep.MINRANGE <= dist and dist <= wep.MAXRANGE)
    -- Target armour type is hittable with this weapon damage type.
    and (g.AMMOMOD[wep.AMMOTYPE][target.ARMOUR])
    -- Weapon is direct, or indirect weapons are allowed.
    and (wep.DIRECT or indirectallowed) then
      table.insert(weplist, i)
    end
  end
  
  return weplist
end
function Unit:join()
  -- Gives HP and supplies to the target, then dies.
  local target = map:getUnit(self.pos)
  target:heal(self.hp)
  target:addfuel(self.fuel)
  for i,wep in ipairs(target.weps) do
    local selfwep = self.weps[i]
    wep:addammo(selfwep.ammo)
  end
  self:die()
end

local wep = {}

local Weapon = class()
function Weapon:init()
  -- Static weapons (with infinite ammo) will never be constructed or call this.
  -- At the moment, there's actually nothing for a static weapon to inherit from Weapon. The fields and methods are useless.
  -- So they could just be tables right now.
  self.ammo = self.MAXAMMO
end
function Weapon:isStatic()
  -- Checks if the weapon can be made static.
  -- Currently, this only checks if the weapon uses ammo or not.
  if not self.MAXAMMO then
    return true
  else
    return false
  end
end

function Weapon:fire()
  if self.MAXAMMO then
    self.ammo = self.ammo - 1
  end
end

function Weapon:addammo(x)
  if self.MAXAMMO == nil then return end
  local newammo = self.ammo + x
  if newammo > self.MAXAMMO then
    self.ammo = self.MAXAMMO
  else
    self.ammo = newammo
  end
end

wep.Rifle = class(Weapon)
statics = {
  NAME = "Rifle",
  DAMAGE = 60,
  AMMOTYPE = g.AMMOTYPES.RIFLE,
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
  AMMOTYPE = g.AMMOTYPES.RIFLE,
  MAXAMMO = 9,
  DIRECT = false,
  MINRANGE = 1,
  MAXRANGE = 3
}
g.addPairs(wep.Missile, statics)
function wep.Missile:init()
  Weapon.init(self)
end

u.Infantry = class(Unit)
statics = {
  NAME = "Infantry",
  CLASS = u.Infantry,
  COST = 1000,
  MOVERANGE = 3,
  MOVETYPE = g.MOVETYPES.INF,
  MAXHP = 100,
  MAXFUEL = 99,
  ARMOUR = g.ARMOURS.VEST,
  WEPS = {[1] = wep.Rifle, [2] = wep.Missile}
  --CAPTURESTRENGTH = 1.0
}
g.addPairs(u.Infantry, statics)
function u.Infantry:init(x, y, teamID)
  self.sprite = "PCW/unitAssets/Default/inf_red_1.png"
  if teamID == g.TEAMS.BLUE then
    self.sprite = "PCW/unitAssets/Default/inf_blue_1.png"
  end
  
  Unit.init(self, x, y, teamID)
end

u.APC = class(Unit)
statics = {
  NAME = "APC",
  CLASS = u.APC,
  COST = 4000,
  MOVERANGE = 6,
  MOVETYPE = g.MOVETYPES.TRACK,
  MAXHP = 100,
  MAXFUEL = 99,
  ARMOUR = g.ARMOURS.H_VEH,
  WEPS = {},
  
  SUPPLIES = true,
  BOARDABLE = g.set{u.Infantry.NAME},
  BOARDCAP = 1
}
g.addPairs(u.APC, statics)
function u.APC:init(x, y, teamID)
  --Ideally you will use ipairs on this array.
  self.boardedunits = {}
  self.sprite = "PCW/unitAssets/Default/apc_red.png"
  self.class = u.APC
  
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

u.UNITS = {
  u.Infantry,
  u.APC
}
u.GROUND_UNITS = {
  u.Infantry,
  u.APC
}
u.SEA_UNITS = {
}
u.AIR_UNITS = {
}

return u