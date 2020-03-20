require "class"
--Don't forget to make a list of defaults and a modifiable version.
--Maybe the defaults are just here, and the game decides whether or not to override.

local u = {}  -- Public.
local inp = {}

-- Will basically just be binding inputs to world methods.
local world
local KEYS
local BUTTONS
local SCROLLUP = -1
local SCROLLDOWN = 1

u.InputMap = class()
function u.InputMap:init(World, inputKeys, inputButtons)
  world = World
  KEYS = inputKeys
  BUTTONS = inputButtons
  
  inp.keyDown = {}
  inp.keyDown[KEYS.MINUS] = world.ReplayUndo
  inp.keyDown[KEYS.EQUALS] = world.ReplayRedo
  inp.keyDown[KEYS.BACKSPACE] = world.ReplayResume
  inp.keyDown[KEYS.J] = world.SaveMap
  inp.keyDown[KEYS.K] = world.LoadMap

  inp.keyUp = {}

  inp.touchDown = {}

  inp.touchUp = {}
  inp.touchUp[BUTTONS.LEFT] = world.PlaceTile

  inp.scrolled = {}
  inp.scrolled[SCROLLUP] = world.ZoomIn
  inp.scrolled[SCROLLDOWN] = world.ZoomOut
end

function u.InputMap:tryBind(itype, ival)
  -- Looks for a bound function, and executes it.
  local bind = inp[itype][ival]
  if bind then
    bind(world)
  end
end

return u