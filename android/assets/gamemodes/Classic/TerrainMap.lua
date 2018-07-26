require "class"
local binser = require "binser"

local g = require "Globals"
local ter = require "Terrains"
local terrains = ter.terrains

local u = {}  -- Public.

local grid = {}
local terrainLayer
local terrainSet

u.TerrainMap = class()
function u.TerrainMap:init(w, h, gameScreen)
  
  --need to load from file at some point.
  
  local java = gameScreen
  terrainLayer = java:newMapLayer("terrain", w, h, 16)
  -- Generate the terrain tileset.
  terrainSet = java:newTileSet("terrain")
  for _,terrain in pairs(terrains) do
    local tile = java:newStaticTile("terrainAssets/Default/" .. terrain.PATH)
    terrainSet:putTile(terrain.ID, tile)
    local resource = binser.registerResource(terrain, terrain.NAME)
  end
  
  -- Init grid and terrain.
  for x=0, w-1 do
    grid[x] = {}
    for y=0, h-1 do
      grid[x][y] = {vector = Vector2(x, y)}
      self:setTerrain(x, y, terrains.SEA, nil)
    end
  end
  
end

function u.TerrainMap:getVector(x, y)
  -- Important when checking vectors by reference, like the A* implementation in UnitMap does.
  -- In such a case, vec1.equals(vec2) will not suffice.
  return grid[x][y].vector
end

function u.TerrainMap:getTerrain(vector)
  return grid[vector.x][vector.y].terrain
end

function u.TerrainMap:setTerrain(x, y, terrain, team)
  
  if terrain.IS_PROPERTY then
    grid[x][y].terrain = terrain(x, y, team)
  else
    grid[x][y].terrain = terrain
  end
  
  --temporary - tile placement based on neighbours is gonna be more complex than this.
  terrainLayer:getCell(x, y):setTile(terrainSet:getTile(terrain.ID))
end

function u.TerrainMap:fill(terrain)
  for x,ytable in ipairs(grid) do
    for y,_ in ipairs(ytable) do
      self:setTerrain(x, y, terrain, nil) -- team is passed from World, in turn received from TileSelectUI.
    end
  end
end

function u.TerrainMap:resize(w, h)
  --not good. should add or crop.
  self.init(self, w, h)
end

function u.TerrainMap:getWidth()
  return #grid + 1
end

function u.TerrainMap:getHeight()
  return #grid[0] + 1
end

function u.TerrainMap:getTerrainSet()
  -- The map editor UI (tile buttons) will want this.
  return terrainSet
end

function u.TerrainMap:saveMap(dir)
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
function u.TerrainMap:loadMap(dir)
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