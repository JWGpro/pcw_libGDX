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

function g.hasKeys(table, args)
  -- Checks if a sequence of keys can be found from a given table.
  -- Prevents you from needing to check nil on each key.
  -- Returns true if all keys exist, false if not. Could also make it return the index of the first nil key.
  
  -- You have to pass a valid table as the first argument.
  local check = table
  for i,v in ipairs(args) do
    if check[v] == nil then
      return false
    end
    check = check[v]
  end
  return true
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

function g.cycle(table, check)
  -- Takes an array-like table and returns the value after the "check" value passed.
  -- It's not really trivial because [i+1] would be nil for the last value.
  for i,v in ipairs(table) do
    if v == check then
      if i < #table then
        return table[i + 1]
      else
        return table[1]
      end
    end
  end
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
  JOIN = "Join"
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
  }
}

return g