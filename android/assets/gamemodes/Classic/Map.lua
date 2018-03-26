require "class"
local g = require "Globals"
local units = require "Units"

local u = {}  -- Public. World is held here, so all its instance vars and methods are public.

-- Received
local java

-- Map constants
local MAP_W
local MAP_H
local CELLSIZE
local MOVERANGE_LAYER
local ATTACKRANGE_LAYER
local MOVERANGE_SET
local ATTACKRANGE_SET

-- Vars
local rangetables = {
  mdestinationcells = {},
  mboardablecells = {},
  mpassagecells = {},
  attackrangecells = {}
}
local TILES  -- Holds tiles to display for each range cell type.
local grid = {}  -- The 2D array grid of the map. For each grid[x][y] position, a ".unit" reference and ".targets" table may exist. Possibly terrain.

u.Map = class()
function u.Map:init(gameScreen, tiledMap, teamUnits, externalDir, uiStage)
  java = gameScreen
  local tiledmap = tiledMap
  
  local prop = tiledmap:getProperties()
  MAP_W = prop:get("width")
  MAP_H = prop:get("height")
  CELLSIZE = prop:get("tilewidth") --Assumes that width and height are identical!
  local layers = tiledmap:getLayers() --MapLayers object. Returned with the Map method, getLayers().
  local layercount = layers:getCount()
  local sets = tiledmap:getTileSets() --TiledMapTileSets object.
  
  --temporary way of getting layers and tiles for now. later will make new layerM and layerA. doesn't matter right now.
  --NOTE: You can get tiles straight from the TiledMapTileSets object, with the "firstgid". This shit is just broken though. How will I make maps?
  for i=0, layercount - 1 do --Assumes layercount>0.
    --CAUTION: This loop assumes that the number of layers equals the number of tilesets!
    local layer = layers:get(i)
    local lname = layer:getName()
    if lname == "Mrange" then
      MOVERANGE_LAYER = layer
    elseif lname == "Arange" then
      ATTACKRANGE_LAYER = layer
    end
    local set = sets:getTileSet(i)
    local setname = set:getName()
    if setname == "MrangeSet" then
      MOVERANGE_SET = set
    elseif setname == "ArangeSet" then
      ATTACKRANGE_SET = set
    end
  end
  
  --set in init, but shouldn't need to be later.
  TILES = {
    mdestinationcells = MOVERANGE_SET:getTile(14),
    mboardablecells = MOVERANGE_SET:getTile(14),
    mpassagecells = MOVERANGE_SET:getTile(15),
    attackrangecells = ATTACKRANGE_SET:getTile(16)
  }
  
  -- Init grid.
  for x=0, MAP_W - 1 do
    grid[x] = {}
    for y=0, MAP_H - 1 do
      grid[x][y] = {}
      --also instantiate Cells for the range layers.
      local cell_m = java:newCell()
      MOVERANGE_LAYER:setCell(x, y, cell_m)
      local cell_a = java:newCell()
      ATTACKRANGE_LAYER:setCell(x, y, cell_a)
    end
  end
  
  units.init(gameScreen, self, teamUnits)
  local inf1 = units.Infantry(12, 12, g.TEAMS.BLUE)
  local inf2 = units.Infantry(16, 16, g.TEAMS.BLUE)
  local inf3 = units.Infantry(15, 15, g.TEAMS.RED)
  local apc1 = units.APC(16, 15, g.TEAMS.RED)
  local inf4 = units.Infantry(49, 49, g.TEAMS.RED)
  
end

function u.Map:displayRanges(selunit)
  local mcells = self:manrange(selunit.x, selunit.y, MAP_W, MAP_H, 0, selunit.movesleft)  -- Must be movesleft, not maxmoves, due to post-boarding.
  
  -- Iterate over the Manhattan circle cells.
  for i,xy in pairs(mcells) do
    --check A* path to cell
    local destination = grid[xy[1]][xy[2]]
    local cell = MOVERANGE_LAYER:getCell(xy[1], xy[2])
    -- Destination conditions:
    -- Cell is empty, or occupied by self.
    if not destination.unit or (destination.unit == selunit) then
      -- Set a movement range tile, store for later retrieval and clearance.
      cell:setTile(TILES.mdestinationcells)
      rangetables.mdestinationcells[xy] = cell
    -- Cell is occupied by a boardable unit. (Allied boardables don't count because they remove control.)
    elseif g.hasKeys(destination.unit, {"BOARDABLE", selunit.NAME})
    and (destination.unit.team == selunit.team)
    and (#destination.unit.boardedunits <= destination.unit.BOARDCAP) then  --DONT FORGET # DOESNT WORK IF INDEXING IS WEIRD
      -- Set a boardable range tile, store for later retrieval and clearance.
      cell:setTile(TILES.mboardablecells) --need it the same for now because of logiccc.
      rangetables.mboardablecells[xy] = cell
    -- Allow ONLY PASSAGE for units of the same or allied TEAMS.
    elseif destination.unit.team == selunit.team then --or ally
      cell:setTile(TILES.mpassagecells)
      rangetables.mpassagecells[xy] = cell
    end
  end
  
  -- Attack ranges:
  
  -- Iterate over weapons.
  for i,wep in ipairs(selunit.weps) do
    -- Iterate over the movement range cells.
    for xy,v in pairs(rangetables.mdestinationcells) do
      -- Proceed if weapon is direct, or cell is the starting location (for indirect weapons).
      if wep.DIRECT or (xy[1] == selunit.x and xy[2] == selunit.y) then
        -- New table for targets from this cell. One for each valid movement cell.
        grid[xy[1]][xy[2]].targets = {}
        -- Get the attack range from the movement cell.
        local acells = self:manrange(xy[1], xy[2], MAP_W, MAP_H, wep.MINRANGE, wep.MAXRANGE)
        -- Iterate over attack range cells.
        for i,vec in pairs(acells) do
          -- Tile cell with an attack range tile.
          local cell = ATTACKRANGE_LAYER:getCell(vec[1], vec[2])
          cell:setTile(TILES.attackrangecells)
          rangetables.attackrangecells[vec] = cell
          -- Get target and add it to the table.
          local target = grid[vec[1]][vec[2]].unit
          if target and (target.team ~= selunit.team) then --or ally. and armour is hittable.
            table.insert(grid[xy[1]][xy[2]].targets, target)
          end
        end
      end
    end
  end
  
end

function u.Map:evaluateActions(actionmenu, selunit, x, y)
  -- Show available actions after a move, based on evaluation of the current state.
  
  -- Board:
  -- If on boardable unit, show Board. Otherwise, evaluate the other actions - which includes the mutually exclusive Wait.
  if g.hasVector2key(rangetables.mboardablecells, {x,y}) then
    actionmenu:showaction(g.ACTS.BOARD)
  else
    -- Attack:
    local targets = grid[x][y].targets
    if targets and (#targets > 0) then
      actionmenu:showaction(g.ACTS.ATTACK)
    end
    -- Unload:
    --(may want to check terrain - be a bit silly if tanks try to unload in the sea and just have to cancel.)
    if selunit.BOARDABLE and (#selunit.boardedunits > 0) then
      actionmenu:showaction(g.ACTS.UNLOAD)
    end
    
    actionmenu:showaction(g.ACTS.WAIT)
  end
end

function u.Map:hideRanges()
  -- Clearing tiles from cells.
  for k,rangetable in pairs(rangetables) do
    for xy,cell in pairs(rangetable) do
      cell:setTile(nil)
    end
  end
end

function u.Map:showRanges()
  -- Reassigning tiles to cells.
  for k,rangetable in pairs(rangetables) do
    for xy,cell in pairs(rangetable) do
      cell:setTile(TILES[k])
    end
  end
end

function u.Map:displayAttackRange(wep, x, y)
  -- For only the current position's attack range, assign tiles to cells. (They can be cleared later as normal.)
  for i,vec in pairs(self:manrange(x, y, MAP_W, MAP_H, wep.MINRANGE, wep.MAXRANGE)) do
    local cell = ATTACKRANGE_LAYER:getCell(vec[1], vec[2])
    cell:setTile(TILES.attackrangecells)
  end
end

function u.Map:clearRanges()
  -- Clearing range tiles (and table) permanently, along with targets.
  for k,rangetable in pairs(rangetables) do
    for xy,cell in pairs(rangetable) do
      cell:setTile(nil)
      if rangetable == rangetables.mdestinationcells then  -- The movement destination cells may refer to target tables, so nil them.
        grid[xy[1]][xy[2]].targets = nil
      end
    end
    rangetables[k] = {}
  end
end

function u.Map:isValidDestination(x, y)
  -- In the movement range layer, get the cell tile at x,y.
  local tile = MOVERANGE_LAYER:getCell(x, y):getTile()
  -- Returns true if there's a destination/boardable tile there.
  return (tile and (tile:getId() == TILES.mdestinationcells:getId() or tile:getId() == TILES.mboardablecells:getId()))
end

function u.Map:getUnit(x, y)
  -- Returns any unit at the given grid reference.
  -- Currently only used for selection and boarding.
  return grid[x][y].unit
end

function u.Map:storeUnitRef(unit)
  -- Should be used whenever a unit newly occupies a unique position.
  -- For example: spawn, wait (but not board).
  grid[unit.x][unit.y].unit = unit
end

function u.Map:killUnitRef(unit)
  -- Should be used when a unit stops occupying the position it is stored at, following some sort of event.
  -- For example: move, die. (In the latter case, no further positional references will be stored.)
  
  -- But we only kill the ref if the coordinates the unit holds, do in fact refer to itself on the grid.
  -- Otherwise, we might kill the ref of its transport.
  if self:getUnit(unit.x, unit.y) == unit then
    grid[unit.x][unit.y].unit = nil
  end
end

function u.Map:getTargets(x, y)
  -- Returns the targets available to the selected unit from the given grid reference.
  return grid[x][y].targets
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

function u.Map:mandist(x, y)
  --"Manhattan distance" of a vector.
	--Takes a vector, gets the absolute, returns Manhattan length.
	--Most appropriately used with short coordinates rather than long.
  local dist = math.floor(math.abs(x) + math.abs(y))
  return dist
end

function u.Map:manrange(startX, startY, mapw, maph, minrange, maxrange)
  --Returns the Manhattan or Taxicab "circle" range from a starting x/y, clamping within a map w/h, taking into account minimum range.
  --Used to get ranges, e.g. for movement and attack.
  --The x and y coordinates of the map may be different, but this function assumes the origin is always 0,0.
  local cellvectors = {}
  
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
        table.insert(cellvectors, {x,y})
      end
    end
  end
  return cellvectors
end

return u