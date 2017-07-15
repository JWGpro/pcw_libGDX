-- Notes:

--  Please, NOTE THE DOT AND COLON NOTATION FOR VARIABLES AND INSTANCE METHODS RESPECTIVELY!
--  camera.zoom = 20
--  camera:rotate(90)
--  Will get userdata type error stuff otherwise.

--At some point I'll have to put a list of methods, and objects, or how to find them in the libGDX API reference.
--Code completion doesn't really work here for them, lol.

-- This will need changing later. Might have to call the LibGDX file handler to get the proper dir.
--package.path = package.path .. ";D:/Desktop/TheProjects/Programming/~libGDX/pcw/android/assets/data/scripts/Classic/?.lua"
--assetdir = "D:/Desktop/TheProjects/Programming/~libGDX/pcw/android/assets/"

-- Look up "recursive require" later. All those units.
--require "Cursor"

-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.
-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.
-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.
-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.
-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.
-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.
-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.
-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.
-- USE LOCAL VARIABLES IN FUNCTIONS MY MAN. SCOPE IS NOT CONTROLLED NORMALLY.

function init(thegamescreen, thecamera, thestage, thetiledMap, theassetdir)
  -- Globally required Java/libGDX objects. Any real point in passing these to every object?
  local gamescreen = thegamescreen
  local camera = thecamera
  local stage = thestage
  local tiledMap = thetiledMap
  assetdir = theassetdir
--  packpage.path = package.path .. ";" .. assetdir .. "PCW/gamemodes/Classic/?.lua"
  
--  luajava.bindClass is for getting static methods.
  cursor = luajava.newInstance("com.pcw.game.InGame.MapActor", assetdir, "PCW/terrain_sprites/Default/283.png", 1.0)
  stage:addActor(cursor)
  stage:setKeyboardFocus(cursor)
  
  -- Now try building the game so it works on your phone and PC and then modify these scripts.
  
end

function loop(delta)
  -- Don't know what will actually end up here yet. You have the timedelta there if you want to play with it. Though anim should be abstracted.
  
end

--Input event handling.

function keyDown(keycode)
  --
end

function keyUp(keycode)
  --
end

function keyTyped(character)
  --
end

function touchDown(screenX, screenY, pointer, button)
  --
end

function touchUp(screenX, screenY, pointer, button)
  --
end

function touchDragged(screenX, screenY, pointer)
  --
end

function mouseMoved(screenX, screenY)
  --
end

function scrolled(amount)
  --
end