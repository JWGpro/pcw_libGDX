require "class"
local g = require "Globals"
local units = require "Units"

local u = {}  -- Public. World is held here, so all its instance vars and methods are public.

-- Received
local java
local terrainmap

-- Map constants
local MAP_W
local MAP_H
local CELLSIZE
local MOVERANGE_LAYER
local ATTACKRANGE_LAYER
local RANGES_SET

-- Vars
local rangetables = {
  mdestinationcells = {},
  mboardablecells = {},
  mpassagecells = {},
  attackrangecells = {}
}
local TILES  -- Holds tiles to display for each range cell type.
local grid = {}  -- The 2D array grid of the map. For each grid[x][y] position, a ".unit" reference and ".targets" table may exist.

u.UnitMap = class()
function u.UnitMap:init(gameScreen, terrainMap, teamUnits)
  java = gameScreen
  terrainmap = terrainMap
  
  MAP_W = terrainmap:getWidth()
  MAP_H = terrainmap:getHeight()
  CELLSIZE = 16 --this is temporary. TerrainMap has the same problem. probably must be defined in a file somewhere.
  
  MOVERANGE_LAYER = java:newMapLayer("moveRange", MAP_W, MAP_H, 16)
  ATTACKRANGE_LAYER = java:newMapLayer("attackRange", MAP_W, MAP_H, 16)
  -- Generate the ranges tileset.
  RANGES_SET = java:newTileSet("ranges")
  local tile
  tile = java:newStaticTile("uiAssets/Default/movetile.png")
  RANGES_SET:putTile(1, tile)
  tile = java:newStaticTile("uiAssets/Default/select.png")
  RANGES_SET:putTile(2, tile)
  tile = java:newStaticTile("uiAssets/Default/attack.png")
  RANGES_SET:putTile(3, tile)
  
  --set in init, but shouldn't need to be later. (what?)
  TILES = {
    mdestinationcells = RANGES_SET:getTile(1),
    mboardablecells = RANGES_SET:getTile(1),
    mpassagecells = RANGES_SET:getTile(2),
    attackrangecells = RANGES_SET:getTile(3)
  }
  
  -- Init grid.
  for x=0, MAP_W - 1 do
    grid[x] = {}
    for y=0, MAP_H - 1 do
      grid[x][y] = {}
    end
  end
  
  units.init(gameScreen, self, teamUnits)
  local inf1 = units.Infantry(13, 12, g.TEAMS.BLUE)
  local inf2 = units.Infantry(12, 11, g.TEAMS.BLUE)
  local inf5 = units.Infantry(13, 10, g.TEAMS.BLUE)
  local inf3 = units.Infantry(14, 11, g.TEAMS.RED)
  local apc1 = units.APC(16, 11, g.TEAMS.RED)
  local inf4 = units.Infantry(18, 9, g.TEAMS.RED)
  
end

function u.UnitMap:displayRanges(selunit)
  -- Movement ranges:
  local mcells = self:manrange(selunit.pos, 0, selunit.movesleft)  -- Must be movesleft, not maxmoves, due to post-boarding.
  
  -- Iterate over the Manhattan circle cells, indicating the maximum range of movement.
  for _,vec in pairs(mcells) do
    -- Proceed if traversable...
    if self:getCost(selunit, vec) then
      local astars = self:astar(selunit, vec)
      -- If an A* path to the cell exists and costs less than movesleft,
      if astars and astars.cost <= selunit.movesleft then
        local destination = grid[vec.x][vec.y]
        local cell = MOVERANGE_LAYER:getCell(vec.x, vec.y)
        -- Destination conditions:
        -- 1: Cell is empty, or occupied by self.
        if not destination.unit or (destination.unit == selunit) then
          -- Set a movement range tile, store for later retrieval and clearance.
          cell:setTile(TILES.mdestinationcells)
          rangetables.mdestinationcells[vec] = cell
        -- 2: Cell is occupied by a boardable unit. (Allied boardables don't count because they remove control.)
        elseif g.hasKeys(destination.unit, {"BOARDABLE", selunit.NAME})
        and (destination.unit.team == selunit.team)
        and (#destination.unit.boardedunits <= destination.unit.BOARDCAP) then  --DONT FORGET # DOESNT WORK IF INDEXING IS WEIRD
          -- Set a boardable range tile, store for later retrieval and clearance.
          cell:setTile(TILES.mboardablecells) --need it the same for now because of logiccc.
          rangetables.mboardablecells[vec] = cell
        -- 3: Allow ONLY PASSAGE for units of the same or allied TEAMS.
        elseif destination.unit.team == selunit.team then --or ally
          cell:setTile(TILES.mpassagecells)
          rangetables.mpassagecells[vec] = cell
        end
      end
    end
  end
  
  -- Attack ranges:
  
  -- Iterate over weapons.
  for _,wep in ipairs(selunit.weps) do
    -- Iterate over the movement range cells.
    for vec,_ in pairs(rangetables.mdestinationcells) do
      -- Proceed if weapon is direct, or cell is the starting location (for indirect weapons).
      local indirectallowed = selunit.pos:equals(vec)
      if wep.DIRECT or indirectallowed then
        -- New table for targets from this cell. One for each valid movement cell.
        grid[vec.x][vec.y].targets = {}
        -- Get the attack range from the movement cell.
        local acells = self:manrange(vec, wep.MINRANGE, wep.MAXRANGE)
        -- Iterate over attack range cells.
        for _,tgt in pairs(acells) do
          -- Tile cell with an attack range tile.
          local cell = ATTACKRANGE_LAYER:getCell(tgt.x, tgt.y)
          cell:setTile(TILES.attackrangecells)
          rangetables.attackrangecells[tgt] = cell
          -- Get target and add it to the table.
          local target = grid[tgt.x][tgt.y].unit
          if target and (target.team ~= selunit.team) and (#selunit:validweps(vec, target, indirectallowed) > 0) then --or ally.
            table.insert(grid[vec.x][vec.y].targets, target)
          end
        end
      end
    end
  end
  
end

function u.UnitMap:isBoardable(vector)
  return g.hasVector2key(rangetables.mboardablecells, vector)
end

function u.UnitMap:getDefence(vector)
  -- Asks the TerrainMap what the defences of the coordinates are.
  return terrainmap:getTerrain(vector).DEFENCE
end

function u.UnitMap:hideRanges()
  -- Clearing tiles from cells.
  for k,rangetable in pairs(rangetables) do
    for _,cell in pairs(rangetable) do
      cell:setTile(nil)
    end
  end
end

function u.UnitMap:showRanges()
  -- Reassigning tiles to cells.
  for k,rangetable in pairs(rangetables) do
    for _,cell in pairs(rangetable) do
      cell:setTile(TILES[k])
    end
  end
end

function u.UnitMap:displayAttackRange(wep, vector)
  -- For only the current position's attack range, assign tiles to cells. (They can be cleared later as normal.)
  for i,vec in pairs(self:manrange(vector, wep.MINRANGE, wep.MAXRANGE)) do
    local cell = ATTACKRANGE_LAYER:getCell(vec.x, vec.y)
    cell:setTile(TILES.attackrangecells)
    rangetables.attackrangecells[vec] = cell
  end
end

function u.UnitMap:clearRanges()
  -- Clearing range tiles (and table) permanently.
  for k,rangetable in pairs(rangetables) do
    for _,cell in pairs(rangetable) do
      cell:setTile(nil)
    end
    rangetables[k] = {}
  end
end

function u.UnitMap:clearTargets()
  for vec,_ in pairs(rangetables.mdestinationcells) do
    grid[vec.x][vec.y].targets = nil
  end
end

function u.UnitMap:isValidDestination(vector)
  -- In the movement range layer, get the cell tile at x,y.
  local tile = MOVERANGE_LAYER:getCell(vector.x, vector.y):getTile()
  -- Returns true if there's a destination/boardable tile there.
  return (tile and (tile:getId() == TILES.mdestinationcells:getId() or tile:getId() == TILES.mboardablecells:getId()))
end

function u.UnitMap:getUnit(vector)
  -- Returns any unit at the given grid reference.
  -- Currently only used for selection and boarding.
  return grid[vector.x][vector.y].unit
end

function u.UnitMap:storeUnitRef(unit)
  -- Should be used whenever a unit newly occupies a position.
  -- For example: spawn, move.
  
  -- But we make sure there's not already a unit in that position.
  -- Otherwise, we could overwrite an APC or something.
  if not self:getUnit(unit.pos) then
    grid[unit.pos.x][unit.pos.y].unit = unit
  end
end

function u.UnitMap:killUnitRef(unit)
  -- Should be used when a unit stops occupying the position it is stored at, following some sort of event.
  -- For example: move, die. (In the latter case, no further positional references will be stored.)
  
  -- But we only kill the ref if the coordinates the unit holds, do in fact refer to itself on the grid.
  -- Otherwise, we might kill the ref of its transport.
  if self:getUnit(unit.pos) == unit then
    grid[unit.pos.x][unit.pos.y].unit = nil
  end
end

function u.UnitMap:getTargets(vector)
  -- Returns the targets available to the selected unit from the given grid reference.
  return grid[vector.x][vector.y].targets
end

function u.UnitMap:getCellsize()
  return CELLSIZE
end

function u.UnitMap:snap(x)
  --Snaps a "long" coordinate onto the grid of cellsize-d cells.
  --"Long" coordinates.
  local coord = CELLSIZE * math.floor(x / CELLSIZE)
  return coord
end

function u.UnitMap:long(x)
  --Upscales a "short" grid coordinate into a "long" coordinate, e.g. for placing in the stage.
  --"Long" coordinates.
  local coord = CELLSIZE * x
  return coord
end

function u.UnitMap:short(x)
  --Downscales a "long" coordinate to a "short" grid coordinate, e.g. for human-readable display.
  --"Short" coordinates.
  local coord = math.floor(x / CELLSIZE)
  return coord
end

function u.UnitMap:manrange(start, minrange, maxrange)
  -- Returns the Manhattan or Taxicab "circle" range from a starting x/y, clamping within a map w/h, taking into account minimum range.
  -- Used to get ranges, e.g. for movement and attack.
  -- The x and y coordinates of the map may be different, but this function assumes the origin is always 0,0.
  local cellvectors = {}
  
  -- Sets the initial x bounds to between +/- maxrange (clamped within the map).
  local minX = g.clampMin(start.x - maxrange, 0)
  local maxX = g.clampMax(start.x + maxrange, MAP_W - 1)

  for x=minX,maxX do
    local xr = math.abs(start.x - x)
    local yrange = maxrange - xr
    -- Sets the y bounds to whatever is left of the range after traversing x (again clamped within the map).
    local minY = g.clampMin(start.y - yrange, 0)
    local maxY = g.clampMax(start.y + yrange, MAP_H - 1)
    for y=minY,maxY do
      local yr = math.abs(start.y - y)
      -- Proceed if Manhattan distance >= minrange.
      if (xr + yr) >= minrange then
        -- Store the coordinates of the valid cell.
        table.insert(cellvectors, terrainmap:getVector(x, y))
      end
    end
  end
  return cellvectors
end

function u.UnitMap:neighbourCells(vector)
  return self:manrange(vector, 1, 1)
end

function u.UnitMap:getCost(selunit, vec)
  -- Evaluates the cost of selunit moving into vector.
  local occupier = self:getUnit(vec)
  local terraincost = terrainmap:getTerrain(vec).MOVECOSTS[selunit.MOVETYPE]
  
  -- Return nil if there's an enemy there.
  if (occupier and occupier.team ~= selunit.team) then
    return nil
  -- Otherwise return the terrain cost, which may also be nil.
  else
    return terraincost
  end
end

local function queueIn(frontier, cell, priority)
  frontier[cell] = priority
end

local function queueOut(frontier)
  local lowest, retcell
  for cell,priority in pairs(frontier) do
    if not lowest or priority < lowest then
      lowest = priority
      retcell = cell
    end
  end
  frontier[retcell] = nil
  return retcell
end

function u.UnitMap:astar(selunit, dest)
  local start = selunit.pos
  local frontier = {}
  queueIn(frontier, start, 0)
  
  local came_from = {}
  local cost_so_far = {}
  came_from[start] = nil
  cost_so_far[start] = 0
  
  -- While the frontier isn't empty,
  local next = next
  while next(frontier) ~= nil do
    -- Get the highest-priorty cell from the frontier.
    local current = queueOut(frontier)
    
    -- If we've reached the destination, return the path and its cost. If not, keep working.
    if current:equals(dest) then
      return {path = came_from[current], cost = cost_so_far[current]}
    end
    
    -- For each neighbour to this cell,
    for _,neighbour in pairs(self:neighbourCells(current)) do
      -- Proceed if traversable...
      local neighbour_cost = self:getCost(selunit, neighbour)
      if neighbour_cost then
        local new_cost = cost_so_far[current] + neighbour_cost
        -- If neighbour hasn't been checked, or this path to it has a lower cost,
        if not cost_so_far[neighbour] or new_cost < cost_so_far[neighbour] then
          -- store the new cost of moving to neighbour,
          cost_so_far[neighbour] = new_cost
          -- put neighbour in the frontier with its checking priority (lower is better),
          local priority = new_cost + neighbour:mandist(dest)
          queueIn(frontier, neighbour, priority)
          -- and store the path.
          came_from[neighbour] = current
        end
      end
    end
  end
  -- No path. (Do we ever even get here?)
  return nil
end


return u