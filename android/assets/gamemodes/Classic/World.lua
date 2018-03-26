require "class"
local g = require "Globals"
local cur = require "Cursor"
local com = require "Commands"
local m = require "Map"
local am = require "ActionMenu"

local u = {}  -- Public. World is held here, so all its instance vars and methods are public.
local pri = {}  -- Selection functions.

-- Constants
local STATES = {DEFAULT = 1, SELECTED = 2, MOVED = 3, ACTING = 4}

local map  -- Contains the grid, handles Units, talks to the ActionMenu.
local actionmenu
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
  map = m.Map(gameScreen, tiledMap, teamunits, externalDir, uiStage)
  actionmenu = am.ActionMenu(gameScreen, externalDir, uiStage, actionfuncs)
  
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

function u.World:updateCamera(x, y)
  -- Updates the camera position.
  cam:translate(x, y)
end

--------------
-- Controls --
--------------
  
function u.World:selectNext()
  -- Advances the selection state using the cursor.
  local curX = map:short(cursor.actor:getX())
  local curY = map:short(cursor.actor:getY())
  
  if state == STATES.DEFAULT then
    --select unit, or deployment building...
    local unit = map:getUnit(curX, curY)
    if unit and unit.movesleft > 0 then  -- Make sure the unit can still move!
      pri.selectunit(unit)
    end
  elseif state == STATES.SELECTED then
    if selunit.team == player  -- Make sure you own the unit!
    and map:isValidDestination(curX, curY) then  -- Make sure the unit can move there!
      pri.moveunit(curX, curY)
    end
  elseif state == STATES.MOVED then
    --Select action.
    --Possibly defer to Scene2D buttons...but you will need to select them with keys too.
    --buttons will be bound to do the relevant stuff. somehow.
  elseif state == STATES.ACTING then
    --Select target and attack it.
    --no because we decided to do it by UI as above. so could it be integrated into action menu...? or need a class for each?
  end
end

function u.World:cancelLast()
  -- Rolls back the selection state.
  if state == STATES.SELECTED then
    pri.deselect()
  elseif state == STATES.MOVED then
    pri.demove()
  elseif state == STATES.ACTING then
    pri.deaction()
  end
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

function u.World:NextTurn()
  -- Restore the units of the current player.
  for i,unit in ipairs(teamunits[player]) do
    unit:restore()
  end
  -- Cycle control.
  player = g.cycle(players, player)
  print("It's " .. player .. "'s turn!")
end

-------------------------
-- Selection functions --
-------------------------

-- Advancing
function pri.selectunit(unit)
  selunit = unit
  map:displayRanges(selunit)
  state = STATES.SELECTED
end

function pri.moveunit(x, y)
  map:hideRanges()
  moveCommand = com.MoveCommand(selunit, x, y)
  actionmenu:displayActions(map, selunit, x, y)
  state = STATES.MOVED
end

function pri.endMove(actionCommand)
  table.insert(history, com.GameMove(moveCommand, actionCommand))
  historyposition = #history
  pri.deselect()
end

-- Retreating
function pri.deselect()
  selunit = nil
  moveCommand = nil
  map:clearRanges()
  actionmenu:clear()
  state = STATES.DEFAULT
end

function pri.demove()
  moveCommand:undo()  -- No need to nil this because the reference will be overwritten by the next MoveCommand.
  map:showRanges()
  actionmenu:clear()
  state = STATES.SELECTED
end

function pri.deaction()
  actionmenu:displayActions(map, selunit, selunit.x, selunit.y)
  map:hideRanges()
  state = STATES.MOVED
end

-----------------------------
-- Action button functions --
-----------------------------
--should these (and the move/action Commands) belong to Units?
--probably not these functions. but the Commands?...

function actionfuncs.Attack()
  state = STATES.ACTING
  actionmenu:clear()  --eventually hide().
  
  --not here probably, but in the UI described below. depends on valid weapons.
  map:displayAttackRange(selunit.weps[1], selunit.x, selunit.y)
  --target icons for each pairs(map:getTargets(selunit.x, selunit.y))
  
  --show new UI screen:
  -- for current weapon (firstwep), show manrange and highlight first target (in targets table).
  --change weapon button(s).
  --change target buttons.
  --battle outcome label.
  --fire button.
end
function actionfuncs.Capture()
  --world.building:capture(unit.hp)
end
function actionfuncs.Supply()
  --for ally in pairs(allies) do ally:resupply() end
end
function actionfuncs.Wait()
  local actionCommand = com.WaitCommand(selunit)
  pri.endMove(actionCommand)
end
function actionfuncs.Board()
  local destunit = map:getUnit(selunit.x, selunit.y)
  local actionCommand = com.BoardCommand(selunit, destunit)
  pri.endMove(actionCommand)
end
function actionfuncs.Deploy()
  --not sure yet, probably similar to Base deploy code.
end
function actionfuncs.Unload()
  --unit buttons showing some info like moves left and HP, maybe allow bring up unit info menu. try to select one with no moves and it bitches.
  
  --for now just assume the APC waits and transfers selection immediately to the infantry.
  --ofc this means if the infantry has no moves then you will select an inf with no moves.
  local cargo = selunit.boardedunits[1]
  local actionCommand = com.UnloadCommand(selunit, cargo)
  pri.endMove(actionCommand)
  --this counts as a move, but in reality you would want to be able to unload consecutive units...
  --possibly you could set movesleft to 0 so the APC can't move, and change the selection criteria...
  --although since it's moved and not waited, it has no ref so you can't select it...
  
  pri.selectunit(cargo)
  
  ----bugs:
  --wait after unload (wait:undo()) does not remember how many movesleft the infantry had; restores it to max with restore().
  --  that could happen if you demoved after an unload-move (it doesn't tho bc the map remembers the range). restore and snapback set to maxmoves.
  --  well the MoveCommand can store that, so just feed it back in...
  --shouldn't be able to deselect an unloaded unit, or use an UNLOADING state so you can undo+pop last move...
  --also, if you undo a move after an unload, it'll put the unit on top of the APC, as it's a discrete move to the APC's.
  --  that would obviously mean you could not select that unit because it's off the grid.
  --  except you can, because snapback overrides the APC's ref. this makes it unselectable from that point on. could add a verify in storeUnitRef.
end

return u