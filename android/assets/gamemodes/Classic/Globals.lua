local g = {}

local cellsize
function g.setCellsize(x)
  cellsize = x
end
function g.getCellsize()
  return cellsize
end

--Temporary...this okay?
--g.gamescreen
--g.grid
--g.teamunits

g.teams = {Neutral = "Neural", Red = "Red", Blue = "Blue", Yellow = "Yellow", Green = "Green"}

--Stub. In World? Only if you want to pass it around. Globals are accessible everywhere.
g.terrain = {}

g.movetypes = {
  Inf = "Infantry",
  Mech = "Mech",
  Tyre = "Tyres",
  Track = "Tracks",
  Air = "Aircraft",
  Ship = "Ship",
  Lander = "Lander"
}

g.armours = {
  Vest = "Ballistic vest",
  LVeh = "Soft-skinned vehicle",
  HVeh = "Amoured vehicle",
  ERA = "Reactive armour",
  Copter = "Helicopter armour"
}

g.ammotypes = {
  RifleRound = "Rifle round",
  CAL50 = ".50 cal",
  HEAT = "HEAT",
  Sabot = "APFSDS"
}

local a = g.armours
local ammo = g.ammotypes
g.ammomod = {
  [ammo.RifleRound] = {
    [a.Vest] = 1,
    [a.LVeh] = 0.5,
    [a.HVeh] = 0.05,
    [a.ERA] = 0.01,
    [a.Copter] = 0.1
  },
  [ammo.CAL50] = {
    [a.Vest] = 1,
    [a.LVeh] = 0.8,
    [a.HVeh] = 0.1,
    [a.ERA] = 0.05,
    [a.Copter] = 0.25
  }
}

function g.snap(x)
  --Snaps a "long" coordinate onto the grid of cellsize-d cells.
  --"Long" coordinates.
  local coord = cellsize * math.floor(x / cellsize)
  return coord
end

function g.long(x)
  --Upscales a "short" grid coordinate into a "long" coordinate, e.g. for placing in the stage.
  --"Long" coordinates.
  local coord = cellsize * x
  return coord
end

function g.short(x)
  --Downscales a "long" coordinate to a "short" grid coordinate, e.g. for human-readable display.
  --"Short" coordinates.
  local coord = math.floor(x / cellsize)
  return coord
end

function g.mandist(x, y)
  --"Manhattan distance" of a vector.
	--Takes a vector, gets the absolute, returns Manhattan length.
	--Most appropriately used with short coordinates rather than long.
  local dist = math.floor(math.abs(x) + math.abs(y))
  return dist
end

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

function g.manrange(startX, startY, mapw, maph, minrange, maxrange)
  --Returns the Manhattan or Taxicab "circle" range from a starting x/y, clamping within a map w/h, taking into account minimum range.
  --Used to get ranges, e.g. for movement and attack.
  --The x and y coordinates of the map may be different, but this function assumes the origin is always 0,0.
  local cells = {}
  
  --Sets the initial x bounds to between +/- maxrange (clamped within the map).
  local minX = g.clampMin(startX - maxrange, 0)
  local maxX = g.clampMax(startX + maxrange, mapw - 1)

  for x=minX,maxX do
    local xr = math.abs(startX - x)
    local yrange = maxrange - xr
    --Sets the y bounds to whatever is left of the range after traversing x (again clamped within the map).
    local minY = g.clampMin(startY - yrange, 0)
    local maxY = g.clampMax(startY + yrange, maph - 1)
    for y=minY,maxY do
      local yr = math.abs(startY - y)
      --Proceed if Manhattan distance >= minrange.
      if (xr + yr) >= minrange then
        --Store the coordinates of the valid cell.
        table.insert(cells, {x,y})
      end
    end
  end
  return cells
end

function g.set(list)
  --Forms a searchable table, with keys set to the intended values, and all values as "true".
  --Can then search like so:
  -- local mytable = g.set{"cat", "dog", "cow"}
  -- if mytable.cat then...
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function g.hasKeys(table, args)
  --Checks if a sequence of keys can be found from a given table.
  --Prevents you from needing to check nil on each key.
  --Returns true if all keys exist, false if not. Could also make it return the index of the first nil key.
  
  --You have to pass a valid table as the first argument.
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
    if (k[1] == vec[1]) and (k[2] == vec[2]) then
      return true
    else
      return false
    end
  end
end

function g.next(table, check)
  -- Takes an array-like table and returns the value after the one passed.
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

return g