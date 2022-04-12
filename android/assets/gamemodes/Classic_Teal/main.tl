local InGameScreen = require("javaclassdefs/InGameScreen")
local OrthographicCamera = require("javaclassdefs/OrthographicCamera")
local Stage = require("javaclassdefs/Stage")
local TiledMap = require("javaclassdefs/TiledMap")

local FuncQueue = require("util/FuncQueue")
local Vector2 = require("util/Vector2")

-- Needed some kind of "interface" declaration here. Dunno if it's sensible.
local IWorld = require("shared/IWorld")
local IInputMap = require("shared/IInputMap")


local MODEPATH = "PCW/gamemodes/Classic_Teal"
-- Teal can't do dynamic requires. But we do know the possible paths in advance.
local CHILD_MODE_CLASSES: {string:{string:function}} = {
    Play = {
        World = function() require("childmodes/play/World") end,
        InputMap = function() require("childmodes/play/InputMap") end
    },
    MapEditor = {
        World = function() require("childmodes/mapeditor/World") end,
        InputMap = function() require("childmodes/mapeditor/InputMap") end
    },
    ReplayViewer = {
        World = function() require("childmodes/replayviewer/World") end,
        InputMap = function() require("childmodes/replayviewer/InputMap") end
    }
}

local q: FuncQueue
local world: IWorld
local inputMap: IInputMap
local lastX: integer
local lastY: integer

function init(
    childmode: string,
    gameScreen: InGameScreen,
    gameCamera: OrthographicCamera,
    gameStage: Stage,
    uiCamera: OrthographicCamera,
    uiStage: Stage,
    tiledMap: TiledMap,
    externalDir: string)

    -- Initialise everything here to prevent any possibility of hanging later!
    package.path =  externalDir .. MODEPATH .. "/?.lua," .. package.path
    
    -- Loading assets...
    local assets = require("assets")
    for class, map in pairs(assets) do
        for _, file in pairs(map) do
            gameScreen:queueLoadAsset(file, class)
        end
    end
    gameScreen:finishLoadingAssets()
    
    q = FuncQueue()

    -- Loads the appropriate World and InputMap for the child mode (Play/MapEditor/ReplayViewer).
    local World = CHILD_MODE_CLASSES[childmode]["World"] as IWorld
    local InputMap = CHILD_MODE_CLASSES[childmode]["InputMap"] as IInputMap

    world = World(gameScreen, gameCamera, tiledMap, externalDir, uiStage, q)
    inputMap = InputMap(world)
end

function runlistener(
    func: function,
    obj: any,
    args,
    event,
    actor)

    -- Runs a listener function (usually from a button) and passes in an object (which may be nil) in case it's an instance method.
    -- Not doing anything with event or actor right now.
    -- TODO: Why is this called args if it isn't varargs? Has only ever taken one arg.
    if obj then
      func(obj, args)
    else
      func(args)
    end
end

function loop(delta: number)
    -- Every frame,
    q:executeNext()  -- Advance the queue.
end

-- Input event handling methods below.
-- All global so Java can find them (for now).
-- Comment in the parameter types for each method, so you know what to expect.

function keyDown(keycode: integer)
    inputMap:tryBind("keyDown", keycode)
end

function keyUp(keycode: integer)
    inputMap:tryBind("keyUp", keycode)
end

function keyTyped(character: string)
    -- Not used...
end

function touchDown(screenX: integer, screenY: integer, pointer: integer, button: integer)
    -- Set for panning; init pan.
    lastX = screenX
    lastY = screenY
    
    world:updateCursor(screenX, screenY)
    inputMap:tryBind("touchDown", button)
end

function touchUp(screenX: integer, screenY: integer, pointer: integer, button: integer)
    inputMap:tryBind("touchUp", button)
end

function touchDragged(screenX: integer, screenY: integer, pointer: integer)
    -- Set for panning; now panning.
    local deltaX = screenX - lastX
    local deltaY = lastY - screenY
    lastX = screenX
    lastY = screenY
  
    -- It appears that you need to set a boolean to pan with MMB, because there is no parameter for the button used to drag.
    -- That param is in touchUp and touchDown, so they can set that boolean.
    -- but eventually u probably control this with world or sth...
    world:translateCamera(deltaX, deltaY)
    world:updateCursor(screenX, screenY)
end

function mouseMoved(screenX: integer, screenY: integer)
    world:updateCursor(screenX, screenY)
end

function scrolled(amount: integer)
    inputMap:tryBind("scrolled", amount)
end

-- Touch gesture detector events below.
-- At the moment, the input multiplexer order means that these events will not be received.
-- Will need to properly return booleans above. Try to conceive of a one-size-fits-all approach here, so that people don't need to fuss with it.

--    @Override
--    public boolean touchDown(x, y, pointer, button) {
--        System.out.println("Java: this was a different touchDown event that took floats"),
--        return true,
--    }

function tap(x: number, y: number, count: integer, button: integer)
    print("tap")
end

function longPress(x: number, y: number)
    print("longpress")
end

function fling(velocityX: number, velocityY: number, button: integer)
    print("fling")
end

function pan(x: number, y: number, deltaX: number, deltaY: number)
    print("pan")
end

function panStop(x: number, y: number, pointer: integer, button: integer)
    print("panstop")
end

function zoom(initialDistance: number, distance: number)
    print("zoom")
end

function pinch(initialPointer1: Vector2, initialPointer2: Vector2, pointer1: Vector2, pointer2: Vector2)
    print("pinch")
end

function pinchStop()
    print("pinchstop")
end
  