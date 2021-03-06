require "class"
local assets = require "Assets"
local g = require "Globals"
local cur = require "Cursor"
local com = require "Commands"
local m = require "Map"
local tui = require "MapEditor/TileSelectUI"

local u = {}  -- Public. World is held here, so all its instance vars and methods are public.
local pri = {}  -- Selection functions.

-- Constants
local STATES = {DEFAULT = 1, SELECTED = 2, MOVED = 3, ACTING = 4}

local extdir
local map
local tileui
local cursor
local cam local offX local offY
local panning = false
local allies = {}
local actionfuncs = {}
local history = {}
local historyposition = 0

-- Selection state
local state = STATES.DEFAULT
local selunit
local moveCommand
-- Players
local players = {g.TEAMS.RED, g.TEAMS.BLUE}  --this is gonna come from java with init ofc. along with map and such. but 1v1 is always RvB.
local player = players[1]
-- Create a list of units for each team.
local teamunits = {}  --u want to give this to whoever is making units. instead of making it g.teamunits.
for i,v in ipairs(players) do
  teamunits[v] = {}
end

u.World = class()
function u.World:init(gameScreen, gameCamera, tiledMap, externalDir, uiStage)
  extdir = externalDir
  
  local skin = gameScreen:getAsset(assets.Skin.DEFAULT)
  
  map = m.Map(30, 20, gameScreen, teamunits)
  tileui = tui.TileSelectUI(gameScreen, skin, externalDir, uiStage, map:getTerrainSet())
  
  cursor = cur.Cursor(gameScreen)
  -- Camera init.
  cam = gameCamera
  cam.zoom = 0.5
  offX = cam.viewportWidth / 2
  offY = cam.viewportHeight / 2
  
  --init/set other UI:
  -- menu
  -- target
  -- unload
  -- link
  -- build/deploy
end

function u.World:updateCursor(x, y)
  -- Updates the cursor position.
  --doesn't work with resizing.
  local newX = map:snap(cam.position.x - ((offX - x) * cam.zoom))
  local newY = map:snap(cam.position.y - ((y - offY) * cam.zoom))
  cursor.actor:setPosition(newX, newY)
end

function u.World:translateCamera(x, y)
  cam:translate(x, y)
end

--------------
-- Controls --
--------------
  
function u.World:PlaceTile()
  -- Places the active tile under the cursor.
  local curX = map:short(cursor.actor:getX())
  local curY = map:short(cursor.actor:getY())
  
  local activetile = tileui:getActiveTile()
  local activeteam = tileui:getActiveTeam()
  map:setTerrain(curX, curY, activetile, activeteam)
  
  --could be units, so needs to be able to move onto the terrain there.
end

function u.World:ZoomIn()
  cam.zoom = cam.zoom / 1.5
end

function u.World:ZoomOut()
  cam.zoom = cam.zoom * 1.5
end

function u.World:ReplayUndo()
  --make sure state is DEFAULT, and set it to REPLAY.
  if historyposition == 0 then
    print("Replay: This is the start of the game!")
  else
    print("Replay: Undoing move " .. historyposition .. "...")
    local previousmove = history[historyposition]
    previousmove:undo()
    historyposition = historyposition - 1
  end
end

function u.World:ReplayRedo()
  if historyposition == #history then
    print("Replay: This is the end of the replay!")
  else
    historyposition = historyposition + 1
    print("Replay: Redoing move " .. historyposition .. "...")
    local nextmove = history[historyposition]
    nextmove:execute()
  end
end

function u.World:ReplayResume()
  --clear beyond historyposition, set state to DEFAULT.
end

function u.World:SaveMap()
  map:saveMap(extdir .. "PCW/maps/test_tbl.map")
end

function u.World:LoadMap()
  map:loadMap(extdir .. "PCW/maps/test_tbl.map")
end

return u