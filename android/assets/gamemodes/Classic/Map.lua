require "class"
local binser = require "binser"

local g = require "Globals"
local units = require "Units"
local ter = require "Terrains"
local terrains = ter.terrains

local u = {}  -- Public.

-- Received
local java

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
local terrainLayer
local terrainSet

u.Map = class()
function u.Map:init(w, h, gameScreen, teamUnits, queue)
  
  --need to load from file at some point.
  
  java = gameScreen
  MAP_W = w
  MAP_H = h
  CELLSIZE = 16
  
  terrainLayer = java:newMapLayer("terrain", w, h, CELLSIZE)
  -- Generate the terrain tileset.
  terrainSet = java:newTileSet("terrain")
  for _,terrain in pairs(terrains) do
    local tile = java:newStaticTile("terrainAssets/Default/" .. terrain.PATH)
    terrainSet:putTile(terrain.ID, tile)
    local resource = binser.registerResource(terrain, terrain.NAME)
  end
  
  -- Init grid and terrain.
  for x=0, MAP_W-1 do
    grid[x] = {}
    for y=0, MAP_H-1 do
      grid[x][y] = {vector = Vector2(x, y)}
      self:setTerrain(x, y, terrains.SEA, nil)
    end
  end
  
  -- Add range display layers.
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
  
  units.init(gameScreen, self, teamUnits, queue)
  local inf1 = units.Infantry(13, 12, g.TEAMS.BLUE)
  local inf2 = units.Infantry(12, 11, g.TEAMS.BLUE)
  local inf5 = units.Infantry(13, 10, g.TEAMS.BLUE)
  local inf3 = units.Infantry(14, 11, g.TEAMS.RED)
  local apc1 = units.APC(16, 11, g.TEAMS.RED)
  local inf4 = units.Infantry(18, 9, g.TEAMS.RED)
  
end

function u.Map:displayRanges(selunit)
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
        elseif g.tryKeys(destination.unit, {"BOARDABLE", selunit.NAME})
        and (destination.unit.team == selunit.team)
        and (#destination.unit.boardedunits <= destination.unit.BOARDCAP) then
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

function u.Map:isBoardable(vector)
  return g.hasVector2key(rangetables.mboardablecells, vector)
end

function u.Map:getDefence(vector)
  return self:getTerrain(vector).DEFENCE
end

function u.Map:hideRanges()
  -- Clearing tiles from cells.
  for k,rangetable in pairs(rangetables) do
    for _,cell in pairs(rangetable) do
      cell:setTile(nil)
    end
  end
end

function u.Map:showRanges()
  -- Reassigning tiles to cells.
  for k,rangetable in pairs(rangetables) do
    for _,cell in pairs(rangetable) do
      cell:setTile(TILES[k])
    end
  end
end

function u.Map:displayAttackRange(wep, vector)
  -- For only the current position's attack range, assign tiles to cells. (They can be cleared later as normal.)
  for i,vec in pairs(self:manrange(vector, wep.MINRANGE, wep.MAXRANGE)) do
    local cell = ATTACKRANGE_LAYER:getCell(vec.x, vec.y)
    cell:setTile(TILES.attackrangecells)
    rangetables.attackrangecells[vec] = cell
  end
end

function u.Map:clearRanges()
  -- Clearing range tiles (and table) permanently.
  for k,rangetable in pairs(rangetables) do
    for _,cell in pairs(rangetable) do
      cell:setTile(nil)
    end
    rangetables[k] = {}
  end
end

function u.Map:clearTargets()
  for vec,_ in pairs(rangetables.mdestinationcells) do
    grid[vec.x][vec.y].targets = nil
  end
end

function u.Map:isValidDestination(vector)
  -- In the movement range layer, get the cell tile at x,y.
  local tile = MOVERANGE_LAYER:getCell(vector.x, vector.y):getTile()
  -- Returns true if there's a destination/boardable tile there.
  return (tile and (tile:getId() == TILES.mdestinationcells:getId() or tile:getId() == TILES.mboardablecells:getId()))
end

function u.Map:getUnit(vector)
  -- Returns any unit at the given grid reference.
  -- Currently only used for selection and boarding.
  return grid[vector.x][vector.y].unit
end

function u.Map:isOnGrid(unit)
  -- Returns true if grid reference points to unit, false if not (vector resolves to a different unit or no unit).
  return self:getUnit(unit.pos) == unit
end

function u.Map:storeUnitRef(unit)
  -- Should be used whenever a unit newly occupies a position.
  -- For example: spawn, move.
  
  -- But we make sure there's not already a unit in that position.
  -- Otherwise, we could overwrite an APC when boarding it.
  if not self:getUnit(unit.pos) then
    grid[unit.pos.x][unit.pos.y].unit = unit
  end
end

function u.Map:killUnitRef(unit)
  -- Should be used when a unit stops occupying the position it is stored at, following some sort of event.
  -- For example: move, die. (In the latter case, no further positional references will be stored.)
  
  -- But we only kill the ref if the coordinates the unit holds, do in fact refer to itself on the grid.
  -- Otherwise, we might kill the ref of its transport.
  if self:isOnGrid(unit) then
    grid[unit.pos.x][unit.pos.y].unit = nil
  end
end

function u.Map:getTargets(vector)
  -- Returns the targets available to the selected unit from the given grid reference.
  return grid[vector.x][vector.y].targets
end

function u.Map:getCellsize()
  return CELLSIZE
end

function u.Map:snap(x)
  --Snaps a "long" coordinate onto the grid of cellsize-d cells.
  --"Long" coordinates.
  local coord = CELLSIZE * math.floor(x / CELLSIZE)
  return coord
end

function u.Map:long(x)
  --Upscales a "short" grid coordinate into a "long" coordinate, e.g. for placing in the stage.
  --"Long" coordinates.
  local coord = CELLSIZE * x
  return coord
end

function u.Map:short(x)
  --Downscales a "long" coordinate to a "short" grid coordinate, e.g. for human-readable display.
  --"Short" coordinates.
  local coord = math.floor(x / CELLSIZE)
  return coord
end

function u.Map:placeActor(actor, vector)
  --Sets the position of a Scene2D actor, assuming the passed vector is in "short" coordinates.
  --use for the cursor too? except that deals with long coords and the camera and shit. not really the same...
  actor:setPosition(self:long(vector.x), self:long(vector.y))
end

function u.Map:manrange(start, minrange, maxrange)
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
        table.insert(cellvectors, self:getVector(x, y))
      end
    end
  end
  return cellvectors
end

function u.Map:neighbourCells(vector)
  return self:manrange(vector, 1, 1)
end

function u.Map:getCost(selunit, vec)
  -- Evaluates the cost of selunit moving into vector.
  local occupier = self:getUnit(vec)
  local terraincost = self:getTerrain(vec).MOVECOSTS[selunit.MOVETYPE]
  
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

function u.Map:astar(selunit, dest)
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
      return {trace = came_from, cost = cost_so_far[current]}
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

function u.Map:getVector(x, y)
  -- Important when checking vectors by reference, like our A* implementation does (i.e. lookup[vector]).
  -- In such a case, vec1:equals(vec2) will not suffice.
  return grid[x][y].vector
end

function u.Map:getTerrain(vector)
  return grid[vector.x][vector.y].terrain
end

function u.Map:setTerrain(x, y, terrain, team)
  
  if terrain.IS_PROPERTY then
    grid[x][y].terrain = terrain(x, y, team)
  else
    grid[x][y].terrain = terrain
  end
  
  --temporary - tile placement based on neighbours is gonna be more complex than this.
  terrainLayer:getCell(x, y):setTile(terrainSet:getTile(terrain.ID))
end

function u.Map:fill(terrain)
  for x,ytable in ipairs(grid) do
    for y,_ in ipairs(ytable) do
      self:setTerrain(x, y, terrain, nil) -- team is passed from World, in turn received from TileSelectUI.
    end
  end
end

function u.Map:resize(w, h)
  --not good. should add or crop.
  self.init(self, w, h)
end

function u.Map:getWidth()
  return #grid + 1
end

function u.Map:getHeight()
  return #grid[0] + 1
end

function u.Map:getTerrainSet()
  -- The map editor UI (tile buttons) will want this.
  return terrainSet
end

function u.Map:saveMap(dir)
  print("Saving map to " .. dir .. "...")
  local map = {}
  for x=0, #grid do
    map[x] = {}
    for y=0, #grid[0] do
      local terrain = self:getTerrain(Vector2(x,y))
      if terrain.IS_PROPERTY then
        map[x][y] = {terrain = terrain.CLASS, team = terrain.team}  -- terrain table plus team.
      else
        map[x][y] = {terrain = terrain}
      end
    end
  end
  binser.writeFile(dir, map)
end
function u.Map:loadMap(dir)
  print("Loading map from " .. dir .. "...")
  local results, len = binser.readFile(dir)
  assert(len == 1)
  local map = results[1]
  
  --ok, this should work for loading larger maps. (actually, you would need to make new Cells...)
  --what about smaller maps? you will have to at least nil the cells remaining in grid so they don't show up.
  for x=0, #map do
    if not grid[x] then
      grid[x] = {}
    end
    for y=0, #map[0] do
      local coord = map[x][y]
      self:setTerrain(x, y, coord.terrain, coord.team)  -- coord.team is nil for static terrains.
    end
  end
  
end

--select multiple, fill selection, copy selection, and paste!
--symmetry too.
--basically see what Tiled does.

return u