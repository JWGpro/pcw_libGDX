require "class"
local g = require "Globals"
local ter = require "Terrains"
local terrains = ter.terrains

local u = {}  -- Public.

local grid = {}  -- For each grid[x][y] position, there is a terrain reference.
local terrainLayer
local terrainSet

u.TerrainMap = class()
function u.TerrainMap:init(w, h, gameScreen)
  
  --need to load from file at some point.
  
  local java = gameScreen
  terrainLayer = java:newMapLayer("terrain", w, h, 16)
  -- Generate the terrain tileset.
  terrainSet = java:newTileSet("terrain")
  for str,vals in pairs(terrains) do
    local tile = java:newStaticTile("terrainAssets/Default/" .. vals.PATH)
    terrainSet:putTile(vals.ID, tile)
  end
  
  -- Init grid and terrain.
  for x=0, w-1 do
    grid[x] = {}
    for y=0, h-1 do
      self:setTerrain(x, y, terrains.SEA)
    end
  end
  
end

function u.TerrainMap:getTerrain(vector)
  return grid[vector.x][vector.y]
end

function u.TerrainMap:setTerrain(x, y, terrain)
  
  if terrain.IS_PROPERTY then
    grid[x][y] = terrain(x, y, g.TEAMS.NEUTRAL)  --actually the team selected in the active tile menu.
  else
    grid[x][y] = terrain
  end
  
  --temporary - tile placement based on neighbours is gonna be more complex than this.
  terrainLayer:getCell(x, y):setTile(terrainSet:getTile(terrain.ID))
end

function u.TerrainMap:fill(terrain)
  for x,ytable in ipairs(grid) do
    for y,_ in ipairs(ytable) do
      self:setTerrain(x, y, terrain)
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

require "SaveTableToFile"

function u.TerrainMap:saveMap()
  print("Saving map...")
  assert(table.save(grid, "test_tbl.lua") == nil)
end

function u.TerrainMap:loadMap()
  print("Loading map...")
  local loadgrid,err = table.load("test_tbl.lua")
  assert(err == nil)
  
  --ok, this should work for loading larger maps. (actually, you would need to make new Cells...)
  --what about smaller maps? you will have to at least nil the cells remaining in grid so they don't show up.
  for x=0, #loadgrid do
    if not grid[x] then
      grid[x] = {}
    end
    for y=0, #loadgrid[0] do
      self:setTerrain(x, y, loadgrid[x][y])
    end
  end
  
  --temporary addition of cities.
  self:setTerrain(10, 10, terrains.City)
  self:setTerrain(12, 10, terrains.City)
  self:setTerrain(13, 10, terrains.Factory)
  self:setTerrain(12, 11, terrains.Port)
  
end
  

--select multiple, fill selection, copy selection, and paste!
--symmetry too.
--basically see what Tiled does.

return u