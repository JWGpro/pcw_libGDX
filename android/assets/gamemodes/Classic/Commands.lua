require "class"
local g = require "Globals"
local f = require "commandfuncs"

local Command = class()
--function Command:execute(world) end
--function Command:undo(world) end

local c = {}

c.Select = class(Command)
function c.Select:execute(world)
  local s = world.states
  local state = world.selection.state
  
  --Drawback: this command can have no effect, but will still be stored in the history. Fix that.
  
  if state == s.DEFAULT then
    --Select unit or deployment building.
    f.select(world)
  elseif state == s.MOVE then
    --Move unit.
    f.move(world)
  elseif state == s.ACT then
    --Select action.
    --Possibly defer to Scene2D buttons...but you will need to select them with keys too.
  elseif state == s.TARGET then
    --Select target.
  end
  
end
function c.Select:undo(world)
  local s = world.states
  local state = world.selection.state
  
  if state == s.DEFAULT then
    --Do nothing. This shouldn't be called ingame, but would in a replay.
  elseif state == s.MOVE then
    --Undo the selection.
    f.undoselect(world)
  elseif state == s.ACT then
    --Undo the movement.
    f.undomove(world)
  elseif state == s.TARGET then
    --Undo the action.
  end
end

c.Cancel = class(Command)
function c.Cancel:execute(world)
  local s = world.states
  local state = world.selection.state
  
  --Possible other state: menu.
  
  if state ~= s.DEFAULT then
    --Progressively cancel the selection by calling its undo method.
    c.Select:undo(world)
  end
end
function c.Cancel:undo(world)
  --Ok to get Command? Otherwise it's just static.
  c.Select:execute(world)
end

c.Menu = class(Command)
function c.Menu:execute(world)
end
function c.Menu:undo()
end

c.ZoomIn = class(Command)
function c.ZoomIn:execute(world)
  local cam = world.camera
  cam.zoom = cam.zoom / 1.5
end

c.ZoomOut = class(Command)
function c.ZoomOut:execute(world)
  local cam = world.camera
  cam.zoom = cam.zoom * 1.5
end

c.PrintCoord = class(Command)
function c.PrintCoord:execute(world)
  local cur = world.cursor.actor
  print(g.short(cur:getX()), g.short(cur:getY()))
end

c.PanStart = class(Command)
function c.PanStart:execute(world)
  world.panning = true
  world.gamescreen:catchCursor(true)
end

c.PanStop = class(Command)
function c.PanStop:execute(world)
  world.panning = false
  world.gamescreen:catchCursor(false)
end

c.Menu = class(Command)
function c.Menu:execute(world)
  world.gamescreen:toggleMenu()
  print("menu toggled")
end

c.RangeAllOn = class(Command)
function c.RangeAllOn:execute(world)
  for k,unit in pairs(world.units) do
    print(unit)
  end
end

c.RangeAllOff = class(Command)
function c.RangeAllOff:execute(world)
  --clear tiles
end

--[[
"make sure every data modification goes through a command"
Therefore you will make units move with Commands, even though there is no control for this.
Everything has to be done with Commands.
Except maybe camera panning...Well, you may want to control camera to show a unit being moved.
Certainly anything you want to be shown in a replay.
]]--
local View = {
  SELECT,
  CONFIRM,
  CANCEL, --undos: select, menu, unit info.
  MENU,
  NEXT_UNIT,
  UNIT_INFO,
  ZOOM_IN,
  ZOOM_OUT,
  CURSOR_LEFT,
  CURSOR_RIGHT,
  CURSOR_UP, --someone may want to traverse menus by scrolling.
  CURSOR_DOWN,
  PAN,
  FAST_PAN,
  --Functions below are menu items not usually bound
  QUIT_TO_MENU,
  CLOSE_GAME,
  SHOW_MAP,
  SHOW_TERRAIN_INFO,
  SHOW_UNIT_INFO,
  SHOW_DAMAGE_CALCULATOR
}

return c