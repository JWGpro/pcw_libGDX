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
  inp.keyDown[KEYS.RIGHT] = world.cursorRight --hold...
  inp.keyDown[KEYS.BACK] = world.cancelLast
--  i.keyDown[KEYS.M] = c.Menu
  inp.keyDown[KEYS.D] = world.PrintDebugInfo
  inp.keyDown[KEYS.R] = world.RangeAllOn
  inp.keyDown[KEYS.E] = world.NextTurn
  inp.keyDown[KEYS.MINUS] = world.ReplayUndo
  inp.keyDown[KEYS.EQUALS] = world.ReplayRedo
  inp.keyDown[KEYS.BACKSPACE] = world.ReplayResume

  inp.keyUp = {}
  inp.keyUp[KEYS.R] = world.cancelLast --cancels RangeAllOn

  inp.touchDown = {}
--  i.touchDown[BUTTONS.MIDDLE] = c.PanStart

  inp.touchUp = {}
  inp.touchUp[BUTTONS.LEFT] = world.selectNext
  inp.touchUp[BUTTONS.RIGHT] = world.cancelLast
--  i.touchUp[BUTTONS.MIDDLE] = c.PanStop

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