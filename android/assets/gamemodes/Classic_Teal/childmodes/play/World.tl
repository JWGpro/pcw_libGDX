local assets = require("assets")
local func = require("util/func")
local Class = require("util/Class")
local FuncQueue = require("util/FuncQueue")
local Vector2 = require("util/Vector2")

local Cursor = require("shared/Cursor")
local Map = require("shared/Map")
local Unit = require("shared/unit/Unit")
local Terrain = require("shared/terrain/Terrain")
local enums = require("shared/enums")

local Command = require("shared/command/Command")
local TurnEnd = require("shared/command/TurnEnd")
local MoveCommand = require("shared/command/MoveCommand")
local AttackCommand = require("shared/command/AttackCommand")
local CaptureCommand = require("shared/command/CaptureCommand")
local SupplyCommand = require("shared/command/SupplyCommand")
local WaitCommand = require("shared/command/WaitCommand")
local BoardCommand = require("shared/command/BoardCommand")
local JoinCommand = require("shared/command/JoinCommand")
local HoldCommand = require("shared/command/HoldCommand")
local UnloadCommand = require("shared/command/UnloadCommand")
local GameMove = require("shared/command/GameMove")

local ActionMenu = require("childmodes/play/ActionMenu")
local DeployMenu = require("childmodes/play/DeployMenu")
local TargetMenu = require("childmodes/play/TargetMenu")
local UnloadMenu = require("childmodes/play/UnloadMenu")

local InGameScreen = require("javaclassdefs/InGameScreen")
local Skin = require("javaclassdefs/Skin")
local OrthographicCamera = require("javaclassdefs/OrthographicCamera")
local Stage = require("javaclassdefs/Stage")
local TiledMap = require("javaclassdefs/TiledMap")

local SelectionState = require("childmodes/play/selectionstate/SelectionState")

-- TODO: setOf? Array? This just looks stupid. Teal enum doesn't facilitate autocomplete though?
--  Maybe I could have some "enum toString" function. Literally just for debug printing though.
local STATES = {
  DEFAULT = "Default",
  SELECTED = "Selected",
  MOVED = "Moved",
  ACTING = "Acting",
  MENU = "Menu",
  BLOCKING = "Blocking"
}


local record World
    --!extends Class
    --/extends

    q: FuncQueue
    map: Map
    actionMenu: ActionMenu
    deployMenu: DeployMenu
    targetMenu: TargetMenu
    unloadMenu: UnloadMenu
    cursor: Cursor
    camera: OrthographicCamera
    offX: number
    offY: number
    panning: boolean
    actionFunctions: {string:function}
    history: {GameMove}
    historyPosition: integer
    teamUnits: {string:{Unit}}
    playerTeams: {string}
    playerTeam: string

    -- Selection state
    state: string
    selectedUnit: Unit
    indirectAllowed: boolean
    moveCommand: MoveCommand
    selectionState: SelectionState

    -- TODO: Maybe just reorder the functions, or put them elsewhere, so no need to define here
    _selectUnit: function(World, Unit)
    _selectProperty: function(World, Terrain)
    _moveUnit: function(World, Vector2)
    _endMove: function(World, Command)
    _cancelUnload: function
    _deselect: function
    _demove: function
    _deaction: function
    _evaluateActions: function
    closeMenus: function
    setCamera: function
    dispatchAttack: function
    dispatchUnload: function
    cyclePlayer: function
    metamethod __call: function(World): World
end
Class.setup(World as table)
function World:_new(
  gameScreen: InGameScreen,
  gameCamera: OrthographicCamera,
  tiledMap: TiledMap,
  externalDir: string,
  uiStage: Stage,
  queue: FuncQueue)

  self.q = queue
  
  self.state = STATES.DEFAULT
  self.panning = false
  self.actionFunctions = {}
  self.history = {}
  self.historyPosition = 0

  -- Create a list of units for each team.
  self.teamUnits = {}
  for _, v in ipairs(self.playerTeams) do
    self.teamUnits[v] = {}
  end

  -- Players
  self.playerTeams = {enums.TEAMS.RED, enums.TEAMS.BLUE}  -- TODO: this is gonna come from java with init ofc. along with map and such. but 1v1 is always RvB.
  self.playerTeam = self.playerTeams[1]
  
  local skin = gameScreen:getAsset(assets.Skin.DEFAULT) as Skin
  
  self.map = Map(30, 20, gameScreen, self.teamUnits, queue)  --load a map here. either in init() or call loadMap().
  self.map:loadMap(externalDir .. "PCW/maps/test_tbl.map")
  
  self.actionMenu = ActionMenu(gameScreen, skin, uiStage, self.actionFunctions)
  -- TODO: Teal doesn't seem to like circular requires.
  --  So instead of passing World, pass the required functions. For now. (TurnEnd also affected.)
  --  World should be rewritten anyway; there are better alternatives here.
  self.deployMenu = DeployMenu(gameScreen, skin, uiStage, self.closeMenus)
  self.targetMenu = TargetMenu(gameScreen, skin, uiStage, self.map, self.setCamera, self.dispatchAttack)
  self.unloadMenu = UnloadMenu(gameScreen, skin, uiStage, self.map, self.dispatchUnload)
  
  self.cursor = Cursor(gameScreen)
  -- Camera init.
  self.camera = gameCamera
  self.camera.zoom = 0.5
  self.offX = gameCamera.viewportWidth / 2
  self.offY = gameCamera.viewportHeight / 2
  
  
  -- TODO:
  --init/set other UI:
  -- menu
  -- build/deploy


  -- TODO: Yeah this is horrific, I'll sort it out soon
  self.actionFunctions.ATTACK = function()
    self.state = STATES.ACTING
    self.actionMenu:clear()  --eventually hide().
    
    local targets = self.map:getTargets(self.selectedUnit.position)
    self.targetMenu:show(self.selectedUnit, targets, self.indirectAllowed)
  end
  function World:dispatchAttack(wepindex: integer, target: Unit)
    local actionCommand = AttackCommand(self.selectedUnit, wepindex, target) as Command
    self:_endMove(actionCommand)
  end
  self.actionFunctions.CAPTURE = function()
    local prop = self.map:getTerrain(self.selectedUnit.position)
    local actionCommand = CaptureCommand(self.selectedUnit, prop) as Command
    self:_endMove(actionCommand)
  end
  self.actionFunctions.SUPPLY = function()
    local targets: {Unit} = {}
    for _,neighbour in ipairs(self.map:neighbourCells(self.selectedUnit.position)) do
      local target = self.map:getUnit(neighbour)
      if target and target.team == self.selectedUnit.team then
        table.insert(targets, target)
      end
    end
    local actionCommand = SupplyCommand(self.selectedUnit, targets) as Command
    self:_endMove(actionCommand)
  end
  self.actionFunctions.WAIT = function()
    local actionCommand = WaitCommand(self.selectedUnit) as Command
    self:_endMove(actionCommand)
  end
  self.actionFunctions.BOARD = function()
    local destunit = self.map:getUnit(self.selectedUnit.position)
    local actionCommand = BoardCommand(self.selectedUnit, destunit) as Command
    self:_endMove(actionCommand)
  end
  self.actionFunctions.DEPLOY = function()
    --not sure yet, probably similar to Base deploy code. Wait until we get the aircraft carrier in.
  end
  self.actionFunctions.UNLOAD = function()
    self.state = STATES.ACTING
    self.actionMenu:clear()  --eventually hide().
    
    self.unloadMenu:show(self.selectedUnit)
  end
  self.actionFunctions.JOIN = function()
    local actionCommand = JoinCommand(self.selectedUnit) as Command
    self:_endMove(actionCommand)
  end
  self.actionFunctions.HOLD = function()
    local actionCommand = HoldCommand() as Command
    self:_endMove(actionCommand)
  end
  function World:dispatchUnload(cargo: Unit)
    local actionCommand = UnloadCommand(self.selectedUnit, cargo) as Command
    self:_endMove(actionCommand)
    
    self:_selectUnit(cargo)
  end
end

function World:updateCursor(x: number, y: number)
  -- Updates the cursor position.
  --  works with: panning, zooming.
  --  doesn't work with: resizing.
  -- TODO: Couldn't the method just operate on a Vector2?
  local newX = self.map:snap(self.camera.position.x - ((self.offX - x) * self.camera.zoom))
  local newY = self.map:snap(self.camera.position.y - ((y - self.offY) * self.camera.zoom))
  self.cursor.actor:setPosition(newX, newY)
end

function World:translateCamera(x: number, y: number)
  self.camera:translate(x, y)
end

function World:setCamera(x: number, y: number)
  self.camera.position.x = x
  self.camera.position.y = y
end

--------------
-- Controls --
--------------

function World:selectNext()
  -- Advances the selection state using the cursor.

  -- TODO: Again, seems overly imperative
  local cursorX = self.map:short(self.cursor.actor:getX())
  local cursorY = self.map:short(self.cursor.actor:getY())
  local cursorPosition = Vector2(cursorX, cursorY)
  
  if self.state == STATES.DEFAULT then
    local unit = self.map:getUnit(cursorPosition)
    local property = self.map:getTerrain(cursorPosition)
    -- Select unit first, then any deployment property beneath.
    if unit and unit:isOrderable() then  -- Make sure the unit can still move!
      self:_selectUnit(unit)
    elseif (property.UNITS_DEPLOYABLE
    and property.team == self.playerTeam
    and (not self.map:getUnit(cursorPosition))) then
      self:_selectProperty(property)
    end
    
  elseif self.state == STATES.SELECTED then
    if self.selectedUnit.team == self.playerTeam  -- Make sure you own the unit!
    and self.map:isValidDestination(cursorPosition) then  -- Make sure the unit can move there!
      self:_moveUnit(cursorPosition)
    end
    
  elseif self.state == STATES.MOVED then
    -- TODO:
    --Select action.
    --Possibly defer to Scene2D buttons...but you will need to select them with keys too.
    --buttons will be bound to do the relevant stuff. somehow.
  elseif self.state == STATES.ACTING then
    --Select target and attack it.
    --no because we decided to do it by UI as above. so could it be integrated into action menu...? or need a class for each?
  elseif self.state == STATES.BLOCKING then
    -- Inputs are blocked while something is happening - probably an animation.
  end
end

function World:cancelLast()
  -- Rolls back the selection state.
  if self.state == STATES.SELECTED and not self.map:isOnGrid(self.selectedUnit) then
    -- Considered selectedUnit to have just unloaded if it isn't on the grid.
    self:_cancelUnload()
  elseif self.state == STATES.SELECTED then
    self:_deselect()
  elseif self.state == STATES.MOVED then
    self:_demove()
  elseif self.state == STATES.ACTING then
    -- For Attack/Unload.
    self:_deaction()
  elseif self.state == STATES.MENU then
    -- Or just closes any menus.
    self:closeMenus()
  elseif self.state == STATES.BLOCKING then
    -- Inputs are blocked while something is happening - probably an animation.
  end
  
end

function World:zoomIn()
  self.camera.zoom = self.camera.zoom / 1.5
end

function World:zoomOut()
  self.camera.zoom = self.camera.zoom * 1.5
end

function World:replayUndo()
  -- Make sure state is DEFAULT, and set it to REPLAY.
  if self.historyPosition == 0 then
    print("Replay: This is the start of the game!")
  else
    local previousMove = self.history[self.historyPosition]
    print("Replay: Undoing command " .. previousMove.name .. " (#" .. self.historyPosition .. ")...")
    previousMove:undo()
    self.historyPosition = self.historyPosition - 1
  end
end

function World:replayRedo()
  if self.historyPosition == #self.history then
    print("Replay: This is the end of the replay!")
  else
    self.historyPosition = self.historyPosition + 1
    local nextMove = self.history[self.historyPosition]
    print("Replay: Redoing command " .. nextMove.name .. " (#" .. self.historyPosition .. ")...")
    nextMove:execute()
  end
end

function World:replayResume()
  -- TODO:
  --clear beyond historyPosition, set state to DEFAULT.
end

function World:rangeAllOn()
  -- Temporary lag testing control: displays all ranges on all units.
  -- Should be cancelable with just a standard deselect.
  for _, units in pairs(self.teamUnits) do
    for _, unit in ipairs(units) do
      self:_selectUnit(unit)
    end
  end
end

function World:printDebugInfo()
  local cursorPosition = Vector2(self.map:short(self.cursor.actor:getX()), self.map:short(self.cursor.actor:getY()))
  local selunitName = "none"
  if self.selectedUnit then selunitName = self.selectedUnit.NAME end
  print("Debug info @ time " .. os.clock() .. ":\n Cursor position: " .. tostring(cursorPosition) .. "\n State: " .. self.state .. "\n self.selectedUnit: " .. selunitName)
end

function World:nextTurn()
  -- TODO: The below cast isn't really legitimate yet
  local command = TurnEnd(self.teamUnits[self.playerTeam], self.cyclePlayer) as GameMove
  table.insert(self.history, command)
  self.historyPosition = #self.history
end

function World:cyclePlayer(direction: integer)
  self.playerTeam = func.cycle(self.playerTeams, self.playerTeam, direction) as string
  local str = "It's " .. self.playerTeam .. "'s turn"
  if direction > 0 then
    str = str .. "!"
  else
    str = str .. " again..."
  end
  print(str)
end  

-------------------------
-- Selection functions --
-------------------------

-- Advancing
function World:_selectUnit(unit: Unit)
  self.selectedUnit = unit
  self.map:displayRanges(self.selectedUnit)
  self.state = STATES.SELECTED
end

function World:_moveUnit(destination: Vector2)
  self.map:hideRanges()
  self.indirectAllowed = (self.selectedUnit.position:equals(destination))
  self.moveCommand = MoveCommand(self.selectedUnit, destination)
  self.state = STATES.BLOCKING
  -- The statements following the MoveCommand must be queued to occur after its finish.
  self.q:queue(function()
      self:_evaluateActions()
      self.state = STATES.MOVED
    end)
end

function World:_endMove(actionCommand: Command)
  table.insert(self.history, GameMove(self.moveCommand, actionCommand))
  self.historyPosition = #self.history
  self:_deselect()
end

function World:_selectProperty(property: Terrain)
  self.deployMenu:show(property)
  self.state = STATES.MENU
end

-- Retreating
function World:_deselect()
  self.selectedUnit = nil
  self.moveCommand = nil
  self.map:clearRanges()
  self.map:clearTargets()
  self.actionMenu:clear()
  self.state = STATES.DEFAULT
end

function World:_demove()
  -- No need to nil moveCommand; the reference will be overwritten by the next MoveCommand.
  self.moveCommand:undo()
  self.map:displayRanges(self.selectedUnit)
  self.actionMenu:clear()
  self.state = STATES.SELECTED
end

function World:_deaction()
  self:_evaluateActions()
  self.targetMenu:clear()
  self.unloadMenu:clear()
  self.state = STATES.MOVED
end

function World:_cancelUnload()
  -- This rolls back one step as you'd expect. It's even less elegant than the last way somehow.
  
  local transport = self.map:getUnit(self.selectedUnit.position)
  
  -- Undo the Unload and remove it from history...
  local unload = self.history[self.historyPosition]
  unload.actionCommand:undo()
  self.historyPosition = self.historyPosition - 1
  
  self:_deselect()  -- Deselect cargo
  self.selectedUnit = transport  -- Select transport (sorta - the only persistent part - same with below statements.)
  self.moveCommand = unload.moveCommand
  self.indirectAllowed = (self.selectedUnit.position:equals(self.moveCommand.origin))
  self.actionFunctions.Unload()  -- Unload menu
end

function World:closeMenus()
  --and any other applicable menu.
  --called from DeployMenu when spawning a unit.
  assert(self.state == STATES.MENU)  -- TODO: are u sure?
  self.deployMenu:clear()
  self.state = STATES.DEFAULT
end

-----------------------------
-- Action button functions --
-----------------------------
-- TODO:
--  should these (and the move/action Commands) belong to Units?
--  probably not these functions. but the Commands?...

function World:_evaluateActions()
  -- Show available actions after a move, based on evaluation of the current state.
  
  -- Board:
  -- If on boardable unit, show Board. Otherwise, evaluate the other actions - which includes the mutually exclusive Wait.
  if self.map:isBoardable(self.selectedUnit.position) then
    self.actionMenu:showAction(enums.ACTS.BOARD)
  else
    -- Capture:
    local prop = self.map:getTerrain(self.selectedUnit.position)
    if prop.IS_PROPERTY and prop.team ~= self.selectedUnit.team then
      self.actionMenu:showAction(enums.ACTS.CAPTURE)
    end
    -- Attack:
    local targets = self.map:getTargets(self.selectedUnit.position)
    if targets and (#targets > 0) then
      self.actionMenu:showAction(enums.ACTS.ATTACK)
    end
    -- Unload:
    if self.selectedUnit.BOARDABLE and (#self.selectedUnit.boardedUnits > 0) then
      for _,unit in ipairs(self.selectedUnit.boardedUnits) do
        if unit:canMove() and self.map:getCost(unit, self.selectedUnit.position) then
          -- If the unit can move, and can disembark where it is...
          self.actionMenu:showAction(enums.ACTS.UNLOAD)
          --however, you only want to add the action ONCE, or it will create new self.actionMenu entries.
          --also, you should have, as an "else", show the button but disabled. maybe disabled buttons give hints when tapped. "units have no moves!"
        end
      end
    end
    -- Supply:
    if self.selectedUnit.CAN_SUPPLY then
      local allies = false
      for _,neighbour in ipairs(self.map:neighbourCells(self.selectedUnit.position)) do
        local unit = self.map:getUnit(neighbour)
        if unit and unit.team == self.selectedUnit.team then  --and can supply the ally
          allies = true
        end
      end
      if allies then
        self.actionMenu:showAction(enums.ACTS.SUPPLY)
      end
    end
    -- Join:
    -- If on a wounded friendly unit of the same type...
    local occupier = self.map:getUnit(self.selectedUnit.position)
    if occupier and (occupier ~= self.selectedUnit) and (self.selectedUnit.NAME == occupier.NAME) and occupier:isWounded() then
      self.actionMenu:showAction(enums.ACTS.JOIN)
    end
    -- Hold:
    -- For now, only transports can Hold. canMove means you can't Hold if it'd leave you with no moves left (that'd be Wait). More like "couldMove".
    -- This is actually relevant for all units, but only really for Supply and Join optimisation, so I think it's just confusing and could cause bad play.
    if self.selectedUnit.BOARDABLE and self.selectedUnit:canMove() then
      self.actionMenu:showAction(enums.ACTS.HOLD)
    end
    
    self.actionMenu:showAction(enums.ACTS.WAIT)
  end
end

return World