--At some point I'll have to put a list of methods, and objects, or how to find them in the libGDX API reference.
--Code completion doesn't really work here for them, lol.

--Everything should use short coords where possible.
--They need to be converted to long for passing to actors. Could override the Java method, but you'd have to do it with a cellsize param.

local modepath = "PCW/gamemodes/Classic"
local world
local inputmap
local queueList = {}

local lastX local lastY

function init(childmode, gameScreen, gameCamera, gameStage, uiCamera, uiStage, tiledMap, externalDir, inputKeys, inputButtons)
  -- Initialise everything here to prevent any possibility of hanging later!
  package.path =  externalDir .. modepath .. "/?.lua;" .. package.path
  -- Loads the appropriate World and InputMap for the child mode (Play/MapEditor/ReplayViewer).
  local w = require(childmode .. "/World")
  local im = require(childmode .. "/InputMap")
  world = w.World(gameScreen, gameCamera, tiledMap, externalDir, uiStage)
  inputmap = im.InputMap(world, inputKeys, inputButtons)
end

function runlistener(func, obj, args, event, actor)
  -- Runs a listener function (usually from a button) and passes in an object (which may be nil) in case it's an instance method.
  -- Not doing anything with event or actor right now.
  if obj then
    func(obj, args)
  else
    func(args)
  end
end

function queue(func, ...)
  -- A FIFO queue of functions and their arguments.
  table.insert(queueList, {func, ...})
end

function blockWhile(func, ...)
  -- Continually adds itself to the front of the queue if the function evaluates to true.
  --you'd think there'd be a cleaner way to defer evaluation of an arbitrary condition...
  if func(...) then
    table.insert(queueList, 1, {blockWhile, func, ...})
  end
end
function loop(delta)
  --should probably be checking this queue constantly until blockWhile...or is that even possible? must be blockWhile would have to signal that?
  if next(queueList) ~= nil then
    local functable = table.remove(queueList, 1)
    local func = table.remove(functable, 1)
    func(table.unpack(functable))
  end
end

-- Input event handling methods below.
-- All global so Java can find them (for now).
-- Comment in the parameter types for each method, so you know what to expect.

function keyDown(keycode)
  inputmap:tryBind("keyDown", keycode)
end

function keyUp(keycode)
  inputmap:tryBind("keyUp", keycode)
end

function keyTyped(character)
  --Not used...
end

function touchDown(screenX, screenY, pointer, button)
  --Set for panning; init pan.
  lastX = screenX
  lastY = screenY
  
  world:updateCursor(screenX, screenY)
  inputmap:tryBind("touchDown", button)
end

function touchUp(screenX, screenY, pointer, button)
  inputmap:tryBind("touchUp", button)
end

function touchDragged(screenX, screenY, pointer)
  --Set for panning; now panning.
  local deltaX = screenX - lastX
  local deltaY = lastY - screenY
  lastX = screenX
  lastY = screenY

  --It appears that you need to set a boolean to pan with MMB, because there is no parameter for the button used to drag.
  --That param is in touchUp and touchDown, so they can set that boolean.
  --but eventually u probably control this with world or sth...
  world:translateCamera(deltaX, deltaY)
  world:updateCursor(screenX, screenY)
  
end

function mouseMoved(screenX, screenY)
  world:updateCursor(screenX, screenY)
end

function scrolled(amount)
  inputmap:tryBind("scrolled", amount)
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
