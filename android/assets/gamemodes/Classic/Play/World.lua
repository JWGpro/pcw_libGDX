require "class"
local g = require "Globals"
local cur = require "Cursor"
local com = require "Commands"
local tm = require "TerrainMap"
local um = require "UnitMap"
local amenu = require "Play/ActionMenu"
local dmenu = require "Play/DeployMenu"
local tmenu = require "Play/TargetMenu"
local umenu = require "Play/UnloadMenu"

local u = {}  -- Public. World is held here, so all its instance vars and methods are public.
local pri = {}  -- Selection functions.

-- Constants
local STATES = {DEFAULT = "Default", SELECTED = "Selected", MOVED = "Moved", ACTING = "Acting", MENU = "Menu"}

local terrainmap -- Contains the terrain grid.
local unitmap  -- Contains the unit grid, handles Units, talks to the ActionMenu...several purposes. Layered on top of TerrainMap.
local actionmenu
local deploymenu
local targetmenu
local unloadmenu
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
local indirectallowed
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
  local fh = gameScreen:reflect("com.badlogic.gdx.files.FileHandle",
    {"String"}, {externalDir .. "PCW/menuskins/Glassy/glassy-ui.json"})
  local skin = gameScreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.Skin",
    {"FileHandle"}, {fh})
  --u need to dispose of this Skin.
  --highly recommend you investigate the AssetManager.
  
  terrainmap = tm.TerrainMap(30, 20, gameScreen)  -- load a map here. either in init() or call loadMap().
  terrainmap:loadMap(externalDir .. "PCW/maps/test_tbl.map")
  unitmap = um.UnitMap(gameScreen, terrainmap, teamunits)
  
  actionmenu = amenu.ActionMenu(gameScreen, skin, uiStage, actionfuncs)
  deploymenu = dmenu.DeployMenu(self, gameScreen, skin, uiStage)
  targetmenu = tmenu.TargetMenu(self, gameScreen, skin, uiStage, unitmap)
  unloadmenu = umenu.UnloadMenu(self, gameScreen, skin, uiStage, unitmap)
  
  cursor = cur.Cursor(gameScreen)
  -- Camera init.
  cam = gameCamera
  cam.zoom = 0.5
  offX = cam.viewportWidth / 2
  offY = cam.viewportHeight / 2
  
  --init/set other UI:
  -- menu
  -- build/deploy
end

function u.World:updateCursor(x, y)
  -- Updates the cursor position.
  --doesn't work with resizing.
  local newX = unitmap:snap(cam.position.x - ((offX - x) * cam.zoom))
  local newY = unitmap:snap(cam.position.y - ((y - offY) * cam.zoom))
  cursor.actor:setPosition(newX, newY)
end

function u.World:translateCamera(x, y)
  cam:translate(x, y)
end

function u.World:setCamera(x, y)
  cam.position.x = x
  cam.position.y = y
end

--------------
-- Controls --
--------------
  
function u.World:selectNext()
  -- Advances the selection state using the cursor.
  local curpos = Vector2(unitmap:short(cursor.actor:getX()), unitmap:short(cursor.actor:getY()))
  
  if state == STATES.DEFAULT then
    local unit = unitmap:getUnit(curpos)
    local prop = terrainmap:getTerrain(curpos)
    -- Select unit first, then any deployment property beneath.
    if unit and unit.movesleft > 0 then  -- Make sure the unit can still move!
      pri.selectunit(unit)
    elseif prop.UNITS_DEPLOYABLE and prop.team == player and (not unitmap:getUnit(curpos)) then
      pri.selectproperty(prop)
    end
    
  elseif state == STATES.SELECTED then
    if selunit.team == player  -- Make sure you own the unit!
    and unitmap:isValidDestination(curpos) then  -- Make sure the unit can move there!
      pri.moveunit(curpos)
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
  if state == STATES.SELECTED and not unitmap:isOnGrid(selunit) then
    -- Considered selunit to have just unloaded if it isn't on the grid.
    pri.cancelunload()
  elseif state == STATES.SELECTED then
    pri.deselect()
  elseif state == STATES.MOVED then
    pri.demove()
  elseif state == STATES.ACTING then
    -- For Attack/Unload.
    pri.deaction()
  elseif state == STATES.MENU then
    -- Or just closes any menus.
    self:closemenus()
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

function u.World:RangeAllOn()
  -- Temporary lag testing control: displays all ranges on all units.
  -- Should be cancelable with just a standard deselect.
  for team,units in pairs(teamunits) do
    for k,unit in pairs(units) do
      pri.selectunit(unit)
    end
  end
end

function u.World:PrintDebugInfo()
  local curpos = Vector2(unitmap:short(cursor.actor:getX()), unitmap:short(cursor.actor:getY()))
  local selunitName = "none"
  if selunit then selunitName = selunit.NAME end
  print("Debug info @ time " .. os.clock() .. ":\n Cursor position: " .. tostring(curpos) .. "\n State: " .. state .. "\n selunit: " .. selunitName)
end

function u.World:NextTurn()
  -- Restore the units of the current player.
  for i,unit in ipairs(teamunits[player]) do
    unit:restore()
  end
  -- Cycle control.
  player = g.cycle(players, player, 1)
  print("It's " .. player .. "'s turn!")
end

-------------------------
-- Selection functions --
-------------------------

-- Advancing
function pri.selectunit(unit)
  selunit = unit
  unitmap:displayRanges(selunit)
  state = STATES.SELECTED
end

function pri.moveunit(destination)
  unitmap:hideRanges()
  indirectallowed = (selunit.pos:equals(destination))
  moveCommand = com.MoveCommand(selunit, destination)
  pri.evaluateActions()
  state = STATES.MOVED
end

function pri.endMove(actionCommand)
  table.insert(history, com.GameMove(moveCommand, actionCommand))
  historyposition = #history
  pri.deselect()
end

function pri.selectproperty(prop)
  deploymenu:show(prop)
  state = STATES.MENU
end

-- Retreating
function pri.deselect()
  selunit = nil
  moveCommand = nil
  unitmap:clearRanges()
  unitmap:clearTargets()
  actionmenu:clear()
  state = STATES.DEFAULT
end

function pri.demove()
  moveCommand:undo()  -- No need to nil this because the reference will be overwritten by the next MoveCommand.
  unitmap:displayRanges(selunit)
  actionmenu:clear()
  state = STATES.SELECTED
end

function pri.deaction()
  pri.evaluateActions()
  targetmenu:clear()
  unloadmenu:clear()
  state = STATES.MOVED
end

function pri.cancelunload()
  -- This rolls back one step as you'd expect. Doesn't look very elegant though.
  local transport = unitmap:getUnit(selunit.pos)
  
  local unload = history[historyposition]
  unload:undo()
  historyposition = historyposition - 1
  
  pri.deselect()
  pri.selectunit(transport)  -- Select
  pri.moveunit(unload.moveCommand.dest)  -- Move
  actionfuncs.Unload()  -- Unload menu
end

function u.World:closemenus()
  --and any other applicable menu.
  --called from DeployMenu when spawning a unit.
  assert(state == STATES.MENU)
  deploymenu:clear()
  state = STATES.DEFAULT
end

-----------------------------
-- Action button functions --
-----------------------------
--should these (and the move/action Commands) belong to Units?
--probably not these functions. but the Commands?...

function pri.evaluateActions()
  -- Show available actions after a move, based on evaluation of the current state.
  
  -- Board:
  -- If on boardable unit, show Board. Otherwise, evaluate the other actions - which includes the mutually exclusive Wait.
  if unitmap:isBoardable(selunit.pos) then
    actionmenu:showaction(g.ACTS.BOARD)
  else
    -- Capture:
    local prop = terrainmap:getTerrain(selunit.pos)
    if prop.IS_PROPERTY and prop.team ~= selunit.team then
      actionmenu:showaction(g.ACTS.CAPTURE)
    end
    -- Attack:
    local targets = unitmap:getTargets(selunit.pos)
    if targets and (#targets > 0) then
      actionmenu:showaction(g.ACTS.ATTACK)
    end
    -- Unload:
    --(check terrain for CARGO - be a bit silly if tanks try to unload in the sea and just have to cancel.)
    if selunit.BOARDABLE and (#selunit.boardedunits > 0) then
      actionmenu:showaction(g.ACTS.UNLOAD)
    end
    -- Supply:
    if selunit.SUPPLIES then
      local allies = false
      for _,neighbour in pairs(unitmap:neighbourCells(selunit.pos)) do
        local unit = unitmap:getUnit(neighbour)
        if unit and unit.team == selunit.team then  --and can supply the ally
          allies = true
        end
      end
      if allies then
        actionmenu:showaction(g.ACTS.SUPPLY)
      end
    end
    -- Join:
    -- If on a wounded friendly unit of the same type...
    local occupier = unitmap:getUnit(selunit.pos)
    if occupier and (occupier ~= selunit) and (selunit.NAME == occupier.NAME) and occupier:isWounded() then
      actionmenu:showaction(g.ACTS.JOIN)
    end
    
    actionmenu:showaction(g.ACTS.WAIT)
  end
end

function actionfuncs.Attack()
  state = STATES.ACTING
  actionmenu:clear()  --eventually hide().
  
  local targets = unitmap:getTargets(selunit.pos)
  targetmenu:show(selunit, targets, indirectallowed)
end
function u.World:dispatchAttack(wepindex, target)
  local actionCommand = com.AttackCommand(selunit, wepindex, target)
  pri.endMove(actionCommand)
end
function actionfuncs.Capture()
  local prop = terrainmap:getTerrain(selunit.pos)
  local actionCommand = com.CaptureCommand(selunit, prop)
  pri.endMove(actionCommand)
end
function actionfuncs.Supply()
  local targets = {}
  for _,neighbour in pairs(unitmap:neighbourCells(selunit.pos)) do
    local target = unitmap:getUnit(neighbour)
    if target and target.team == selunit.team then
      table.insert(targets, target)
    end
  end
  local actionCommand = com.SupplyCommand(selunit, targets)
  pri.endMove(actionCommand)
end
function actionfuncs.Wait()
  local actionCommand = com.WaitCommand(selunit)
  pri.endMove(actionCommand)
end
function actionfuncs.Board()
  local destunit = unitmap:getUnit(selunit.pos)
  local actionCommand = com.BoardCommand(selunit, destunit)
  pri.endMove(actionCommand)
end
function actionfuncs.Deploy()
  --not sure yet, probably similar to Base deploy code. Wait until we get the aircraft carrier in.
end
function actionfuncs.Unload()
  state = STATES.ACTING
  actionmenu:clear()  --eventually hide().
  
  unloadmenu:show(selunit)
  ----bugs:
  --wait after unload (wait:undo()) does not remember how many movesleft the infantry had; restores it to max with restore().
  --  that could happen if you demoved after an unload-move (it doesn't tho bc the map remembers the range). restore and snapback set to maxmoves.
  --  well the MoveCommand can store that, so just feed it back in...
end
function u.World:dispatchUnload(cargo)
  local actionCommand = com.UnloadCommand(selunit, cargo)
  pri.endMove(actionCommand)
  
  pri.selectunit(cargo)
end
function actionfuncs.Join()
  local actionCommand = com.JoinCommand(selunit)
  pri.endMove(actionCommand)
end


return u