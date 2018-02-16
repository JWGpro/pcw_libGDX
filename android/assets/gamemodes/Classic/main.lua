--At some point I'll have to put a list of methods, and objects, or how to find them in the libGDX API reference.
--Code completion doesn't really work here for them, lol.
--"Attempt to call table" could mean you are trying to do "for k,v in table" - you need pairs(table) or ipairs(table).

--Everything should use short coords where possible.
--They need to be converted to long for passing to actors. Could override the Java method, but you'd have to do it with a cellsize param.

--[[
--For printing tables.
  for k, v in pairs(table) do
    print(k, v)
  end
]]--

local g
local i
local u
local f

local world = {}

world.grid = {}
world.units = {}
world.map = {}
world.cursor = nil
world.panning = false
local lastX local lastY local offX local offY
world.states = {DEFAULT = 1, MOVE = 2, ACT = 3, TARGET = 4} --Globals?
world.acts = {Attack = "Attack", Capture = "Capture", Supply = "Supply", Wait = "Wait", Board = "Board", Deploy = "Deploy"}

--Contains all the state modifiable through the selection process.
world.selection = {}
local sel = world.selection
sel.state = world.states.DEFAULT
sel.mrangetiles = {}
sel.arangetiles = {}
--[[ And these uninitialised variables:
sel.unit
sel.startX
sel.startY
sel.maxmoves
sel.movesleft
]]--

--Command history.
--Don't think this needs to be mutable here, because a replay should show the entire history.
--If this was an editor, you could undo Commands, and then pop them if they did something else.
--
--The replay may need each Command to self. the world as a snapshot, or snapshot by other means.
local history = {}

function init(thegamescreen, thecamera, gamestage, theUIcamera, theUIstage, thetiledMap, theextdir)
  world.gamescreen = thegamescreen
  world.camera = thecamera
  local gstage = gamestage
  world.UIcamera = theUIcamera
  world.UIstage = theUIstage
  local tiledMap = thetiledMap --TiledMap object.
  world.extdir = theextdir
  
  --Might want to import everything here upfront to prevent any possibility of hanging later!
  package.path =  world.extdir .. "PCW/gamemodes/Classic/?.lua;" .. package.path
  g = require "Globals"
  i = require "InputMap"
  u = require "Units"
  f = require "commandfuncs"
  require "Cursor"
  
  world.camera.zoom = 0.5
  offX = world.camera.viewportWidth / 2
  offY = world.camera.viewportHeight / 2
  
  --Map data storage, cellsize acquisition.
  --Since the range layer always starts off empty, might be a better idea to add it programmatically than force users to add it in maps!
  local prop = tiledMap:getProperties()
  world.map.w = prop:get("width")
  world.map.h = prop:get("height")
  g.setCellsize(prop:get("tilewidth")) --Assumes that width and height are identical!
  local layers = tiledMap:getLayers() --MapLayers object. Returned with the Map method, getLayers().
  local layercount = layers:getCount()
  local sets = tiledMap:getTileSets() --TiledMapTileSets object.
  --NOTE: You can get tiles straight from the TiledMapTileSets object, with the "firstgid". This shit is just broken though. How will I make maps?
  world.map.layers = {}
  world.map.tilesets = {}
  for i=0, layercount-1 do --Assumes layercount>0.
    --CAUTION: This loop assumes that the number of layers equals the number of tilesets!
    local layer = layers:get(i)
    local lname = layer:getName()
    world.map.layers[lname] = layer --Stores a TiledMapTileLayer object under its name.
    local set = sets:getTileSet(i)
    local setname = set:getName()
    world.map.tilesets[setname] = set --Stores a TiledMapTileSet object under its name.
  end
  
  --Create the map grid, in which units, tiles, targets etc. can be stored.
  for x=0, world.map.w do
    world.grid[x] = {}
    for y=0, world.map.h do
      world.grid[x][y] = {}
      --Also instantiate Cells for the range layers.
      local cellM = world.gamescreen:newCell()
      world.map.layers.Mrange:setCell(x, y, cellM)
      local cellA = world.gamescreen:newCell()
      world.map.layers.Arange:setCell(x, y, cellA)
    end
  end
  
  --Initialise unit-related UI.
  f.UIinit(world)
  
  --The constructor for units should also register them with a list of units.
  local inf1 = u.Infantry(world.gamescreen, g.getCellsize(), 0, 0, world)
  local inf2 = u.Infantry(world.gamescreen, g.getCellsize(), 10, 10, world)
  local inf3 = u.Infantry(world.gamescreen, g.getCellsize(), 15, 15, world)
  local inf4 = u.Infantry(world.gamescreen, g.getCellsize(), 49, 49, world)
--  print(world.grid[80][48]:getWeps())
  
  world.cursor = Cursor.new(world.gamescreen, g.getCellsize())
--  stage:setKeyboardFocus(cursor)
end

function runlistener(func, object, event, actor)
  --Runs a listener function (usually from a button) and passes in an object in case it's an instance method.
  --That's the same as object:func() in that case, but for some reason that doesn't work. Maybe due to how the function is passed?
  func(object)
end

function loop(delta)
  -- Don't know what will actually end up here yet. You have the timedelta there if you want to play with it. Though anim should be abstracted.
--  print(#history)
end

--Input event handling methods below.
-- Comment in the parameter types for each method, so you know what to expect.
--At the moment, correctly ignores unbound keys, but may not properly instantiate commands...

function keyDown(keycode)
  local command = i.keyDown[keycode]
  if command ~= nil then
    command():execute(world)
    table.insert(history, command)
  end
end

function keyUp(keycode)
  local command = i.keyUp[keycode]
  if command ~= nil then
    command():execute(world)
    table.insert(history, command)
  end
end

function keyTyped(character)
  --Not used...
end

function touchDown(screenX, screenY, pointer, button)
  --Set for panning.
  lastX = screenX
  lastY = screenY
  
  --Update cursor.
  local cam = world.camera
  local newX = g.snap(cam.position.x - ((offX - screenX) * cam.zoom))
  local newY = g.snap(cam.position.y - ((screenY - offY) * cam.zoom))
  world.cursor.actor:setPosition(newX, newY)
  
  local command = i.touchDown[button]
  if command ~= nil then
    command():execute(world)
    table.insert(history, command)
  end
end

function touchUp(screenX, screenY, pointer, button)
  local command = i.touchUp[button]
  if command ~= nil then
    command():execute(world)
    table.insert(history, command)
  end
end

function touchDragged(screenX, screenY, pointer)
  --Set for panning.
  local deltaX = screenX - lastX
  local deltaY = lastY - screenY
  lastX = screenX
  lastY = screenY

  --It appears that you need this boolean to pan with MMB, because there is no parameter for the button used to drag.
--  if world.panning then
    local cam = world.camera
    cam:translate(deltaX, deltaY)
--  else
    --Update cursor.
--    local cam = world.camera
    local newX = g.snap(cam.position.x - ((offX - screenX) * cam.zoom))
    local newY = g.snap(cam.position.y - ((screenY - offY) * cam.zoom))
    world.cursor.actor:setPosition(newX, newY)
--  end
  
end

function mouseMoved(screenX, screenY)
  --Update cursor.
  local cam = world.camera
  local newX = g.snap(cam.position.x - ((offX - screenX) * cam.zoom))
  local newY = g.snap(cam.position.y - ((screenY - offY) * cam.zoom))
  world.cursor.actor:setPosition(newX, newY)
end

function scrolled(amount)
  local command = i.scrolled[amount]
  if command ~= nil then
    command():execute(world)
    table.insert(history, command)
  end
end

--Touch gesture detector events below.
-- At the moment, the input multiplexer order means that these events will not be received.
-- Will need to properly return booleans above. Try to conceive of a one-size-fits-all approach here, so that people don't need to fuss with it.

--    @Override
--    public boolean touchDown(x, y, pointer, button) {
--        System.out.println("Java: this was a different touchDown event that took floats");
--        return true;
--    }

function tap(x, y, count, button)
  print("tap")
end

function longPress(x, y)
  print("longpress")
end

function fling(velocityX, velocityY, button)
  print("fling")
end

function pan(x, y, deltaX, deltaY)
  print("pan")
end

function panStop(x, y, pointer, button)
  print("panstop")
end

function zoom(initialDistance, distance)
  print("zoom")
end

function pinch(initialPointer1, initialPointer2, pointer1, pointer2)
  print("pinch")
end

function pinchStop()
  print("pinchstop")
end
