require "class"

-------------
-- Classes --
-------------

Vector2 = class()
function Vector2:init(x, y)
  self.x = x
  self.y = y
end
function Vector2:__tostring()
  return self.x .. "," .. self.y
end
function Vector2:add(vec)
  return Vector2(self.x + vec.x, self.y + vec.y)
end
function Vector2:subtract(vec)
  return Vector2(self.x - vec.x, self.y - vec.y)
end
function Vector2:equals(vec)
  return (self.x == vec.x and self.y == vec.y)
end
function Vector2:mandist(vec)
  -- "Manhattan distance" to another vector.
  return math.abs(self.x - vec.x) + math.abs(self.y - vec.y)
end

-- A FIFO queue of anonymous functions holding arbitrary code.
FuncQueue = class()
function FuncQueue:init()
  self.queueList = {}
  self.endtime = nil
  self.framecount = 0  --unlikely to be useful beyond debugging.
end
function FuncQueue:__tostring()
  --print everything in it i guess. how do you print a function name? (u cant)
  for k,v in pairs(self.queueList) do
    print(k,v)
  end
end
function FuncQueue:queue(func)
  --[[
  -- Takes blocks of code in anonymous functions:
  q:queue(function()
      print(1)
      print(2)
    end)
    
  -- Something which sadly doesn't work is this:
  function FuncQueue:queuealt(code)
    table.insert(self.queueList, function() return code end)
  end
  -- Valid syntax with comma-separated statements, but they are executed immediately (before queuealt is called):
  q:queuealt(
    print(1),
    print(2)
  )
  ]]--
  table.insert(self.queueList, func)
--  print("Queued", func)
end
function FuncQueue:shunt(func)
  -- Moves something to the front of the queue. Should only be for blocking.
  table.insert(self.queueList, 1, func)
--  print("Shunted", func)
end
function FuncQueue:blockWhile(eval)
  if eval() then
    self:shunt(function()
        self:blockWhile(eval)
      end)
  end
end
function FuncQueue:queueBlockWhile(eval)
  --[[
  -- Delays execution of queued functions if the passed function evaluates to true.
  -- e.g.:
  q:queueBlockWhile(function()
          return self:isMoving()
        end)
  -- Of course, with the above format, you can just "return not self:isMoving()" if desired.
  --you'd think there'd be a cleaner way to defer evaluation of an arbitrary condition...
  ]]--
  self:queue(function()
      self:blockWhile(eval)
    end)
end
function FuncQueue:blockFor(seconds)
  if seconds then
    self.endtime = os.clock() + seconds
  end
  if os.clock() < self.endtime then
    self:shunt(function()
        self:blockFor(nil)
      end)
  end
end
function FuncQueue:queueBlockFor(seconds)
  --[[
  -- Delays execution of queued functions for the duration passed.
  -- e.g.:
  q:queueBlockFor(1)
  ]]--
  self:queue(function()
      self:blockFor(seconds)
    end)
end
function FuncQueue:executeNext()
  --increment the frame count
  self.framecount = self.framecount + 1
  -- Get and execute the first function (only) in the queue. Only the first for some reason...you could try executing all until reaching a blockWhile.
  if next(self.queueList) ~= nil then
    local func = table.remove(self.queueList, 1)
--    print("Executing next in queue (len " .. #self.queueList .. ", frame " .. self.framecount .. "):", func)
    func()
  end
end

local g = {}

---------------
-- Functions --
---------------

function g.clampMin(n, min)
  if n < min then
    return min
  else
    return n
  end
end

function g.clampMax(n, max)
  if n > max then
    return max
  else
    return n
  end
end

function g.set(list)  --maybe this should be called "search".
  -- Forms a searchable table from an array, with keys set to the intended values, and all values as "true".
  -- Can then search like so:
  --  local mytable = g.set{"cat", "dog", "cow"}
  --  if mytable.cat then...
  local set = {}
  for i,v in ipairs(list) do
    set[v] = true
  end
  return set
end

function g.tryKeys(table, args)
  -- Tries a sequence of keys on a given table. For example, table[unit][1].
  -- Prevents you from needing to check nil on each key.
  -- Returns the final value if all keys exist, nil if not. Could also make it return/print the index of the first nil key.
  
  -- You have to pass a valid table as the first argument.
  local check = table
  for i,v in ipairs(args) do
    if check[v] == nil then
      return nil
    end
    check = check[v]
  end
  return check
end

function g.addPairs(table, keypairs)
  -- This is simply meant to reduce repetition when adding several k,v pairs. For example:
  --  u.Infantry.NAME = "Infantry"
  --  u.Infantry.COST = 1000
  --  ...
  -- Becomes:
  --  statics = {NAME = "Infantry", COST = 1000, ...}
  --  g.addPairs(u.Infantry, statics)
  for k,v in pairs(keypairs) do
    table[k] = v
  end
end

function g.hasVector2key(table, vec)
  -- Assumes that the table's keys are entirely Vector2s, then checks them against the passed vector.
  for k,v in pairs(table) do
    if k:equals(vec) then
      return true
    else
      return false
    end
  end
end

function g.cycle(table, check, direction)
  -- Takes an array-like table and returns a value relative to the position of the check.
  -- When direction == 1, cycles forwards (returning the next value). When direction == -1, cycles backwards.
  -- But values other than 1 and -1 should work too.
  for i,v in ipairs(table) do
    if v == check then
      -- (i + direction) gives the sought index. Modulo forces it to cycle inside the table.
      -- +1 gives Lua-valid indexes (e.g. 1-3 instead of 0-2).
      -- -1 fixes offset for Lua indexing (e.g. 0 >> #table, 1 >> 1 instead of -1 >> #table, 0 >> 1).
      local index = ((i + direction - 1) % #table) + 1
      return table[index]
    end
  end
end

function g.damageCalc(Aclass, Ahp, Awep, Dclass, Dhp, Ddef)
  -- HP is expected to be passed raw (1-100). It's converted to a float with step 0.1 (0.1, 0.2...1.0).
  local attackerstrength = math.ceil((Ahp / Aclass.MAXHP) * 10) / 10
  local defenderstrength = math.ceil((Dhp / Dclass.MAXHP) * 10) / 10
  local weapon = Aclass.WEPS[Awep]
  -- Look up the modifier for the ammo type on the defender's armour.
  local armourpenalty = g.AMMOMOD[weapon.AMMOTYPE][Dclass.ARMOUR]
  -- Terrain defences subtract 10% of damage for each star, but the effect is proportional to the defender's strength.
  local defstars
  -- And defences do not apply to air units.
  if Dclass.MOVETYPE == g.MOVETYPES.AIR then
    defstars = 0
  else
    defstars = Ddef
  end
  local terrainpenalty = (1 - (0.1 * defstars * defenderstrength))
  
  return attackerstrength * weapon.DAMAGE * armourpenalty * terrainpenalty
end

---------------
-- Constants --
---------------

g.TEAMS = {
  NEUTRAL = "Neutral",
  RED = "Red",
  BLUE = "Blue",
  YELLOW = "Yellow",
  GREEN = "Green"
}
g.ACTS = {
  ATTACK = "Attack",
  CAPTURE = "Capture",
  SUPPLY = "Supply",
  WAIT = "Wait",
  BOARD = "Board",
  DEPLOY = "Deploy",
  UNLOAD = "Unload",
  JOIN = "Join",
  HOLD = "Hold"
}

g.MOVETYPES = {
  INF = "Infantry",
  MECH = "Mech",
  TYRE = "Tyres",
  TRACK = "Tracks",
  AIR = "Aircraft",
  SHIP = "Ship",
  LANDER = "Lander"
}

g.ARMOURS = {
  VEST = "Ballistic vest",
  L_VEH = "Soft-skinned vehicle",
  H_VEH = "Amoured vehicle",
  ERA = "Reactive armour",
  COPTER = "Helicopter armour"
}

g.AMMOTYPES = {
  RIFLE = "Rifle round",
  CAL50 = ".50 cal",
  HEAT = "HEAT",
  SABOT = "APFSDS"
}

local A = g.ARMOURS
local AMMO = g.AMMOTYPES
g.AMMOMOD = {
  [AMMO.RIFLE] = {
    [A.VEST] = 1,
    [A.L_VEH] = 0.5,
    [A.H_VEH] = 0.05,
    [A.ERA] = 0.01,
    [A.COPTER] = 0.1
  },
  [AMMO.CAL50] = {
    [A.VEST] = 1,
    [A.L_VEH] = 0.8,
    [A.H_VEH] = 0.1,
    [A.ERA] = 0.05,
    [A.COPTER] = 0.25
  },
  [AMMO.SABOT] = {
    [A.COPTER] = 1
  }
}

return g