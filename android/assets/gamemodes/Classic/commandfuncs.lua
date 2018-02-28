local g = require "Globals"

local f = {}

local actiontable
local actionbuttons = {}
local actions = {}
local weaponbuttontable

function f.UIinit(world)
  gs = world.gamescreen
  --Create the actions menu for later modification.
  --Reflection is relatively slow, so this sort of thing should be done once at the game's start.
  actiontable = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table", {}, {})
  world.UIstage:addActor(actiontable)
  actiontable:setFillParent(true)
  actiontable:top()
  actiontable:left()
  actiontable:pad(10)
--  world.UIcamera.zoom = world.UIcamera.zoom * 2
  local fh = world.gamescreen:reflect("com.badlogic.gdx.files.FileHandle", {"String"}, {world.extdir .. "PCW/menuskins/Glassy/glassy-ui.json"})
  local skin = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.Skin", {"FileHandle"}, {fh})
  --You need to dispose of this Skin.
  --Highly recommend you investigate the AssetManager.
  --As long as you declared the actions table with integers for keys, ipairs will maintain order while iterating. pairs does not.
  for act,str in pairs(world.acts) do
    --Create a button for each action.
    local button = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {act, skin})
    --Store button.
    actionbuttons[str] = button
    --Add listener to a function here.
    world.gamescreen:addChangeListener(button, actions[str], world)
  end
  
  --Weapon switch button.
  weaponbuttontable = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table", {}, {})
  world.UIstage:addActor(weaponbuttontable)
  weaponbuttontable:setFillParent(true)
  weaponbuttontable:bottom()
  weaponbuttontable:right()
  weaponbuttontable:pad(10)
  local weaponbutton = world.gamescreen:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {"a", skin})
--  weaponbuttontable:add(weaponbutton)
  --add a listener for a keyboard button. though that needs to be input mapped.
end
local function showaction(action)
  --Get button.
  local button = actionbuttons[action]
  --Add to table.
  actiontable:add(button)
  --Next row.
  actiontable:row()
end
local function clearactions()
  actiontable:clearChildren()
end
function actions.Attack(world)
  local sel = world.selection
  sel.state = world.states.TARGET
  local selunit = sel.unit
  clearactions()
  --Show target icons over targets and possibly attack range from cell too.
  for i,target in pairs(world.grid[selunit.x][selunit.y].targets) do
    local cell = world.map.layers.Arange:getCell(target.x, target.y) --if team checking was off, you could target yourself within 1 space.
    cell:setTile(world.map.tilesets.ArangeSet:getTile(16)) --Attack range tile.
    sel.arangetiles[{target.x,target.y}] = cell
  end
  --Show the weapon switch button (if multiple weapons are valid).
  --Now wait for a Select command in this new state.
end
function actions.Capture(world)
  --world.building:capture(unit.hp)
end
function actions.Supply(world)
  --for ally in pairs(allies) do ally:resupply() end
end
function actions.Wait(world)
  local selunit = world.selection.unit
  selunit:wait()
  --Reset state.
  clearactions()
  f.undoselect(world)
end
function actions.Board(world)
  local selunit = world.selection.unit
  local destunit = world.grid[selunit.x][selunit.y].unit
  selunit:board(destunit)
  clearactions()
  f.undoselect(world)
end
function actions.Deploy(world)
  --not sure yet, probably similar to Base deploy code.
end
function actions.Unload(world)
  local selunit = world.selection.unit
  --for i,unit in ipairs(unit.boardedunits) do
  --  button showing some info like moves left and HP, maybe allow bring up unit info menu. try to select one with no moves and it bitches.
  --end
  --wait for a button to be pressed
  
  --for now just assume the APC waits and transfers selection immediately to the infantry:
  selunit:wait()
  clearactions()
  f.undoselect(world)
  
  local cargo = selunit.boardedunits[1]
  cargo:disembark(world, selunit)
end

function f.select(world, disembarkunit)
  local unit
  
  if disembarkunit then
    -- Don't worry about movesleft for now - that should be checked prior to unload.
    unit = disembarkunit
  else
    --Lookup the cursor position in the unit list to return any unit there.
    local cur = world.cursor.actor
    local x = g.short(cur:getX())
    local y = g.short(cur:getY())
    --At the moment, this will return an "attempt to index nil" error if you call it beyond the bounds of the map.
    --But at some point I should have it so you can't see beyond the map anyway.
    unit = world.grid[x][y].unit
    
    --Stop if there's no unit, or the unit has no moves left.
    if not unit or unit.movesleft == 0 then return end
  end
  --Select unit - set state and store unit.
  local sel = world.selection
  sel.state = world.states.MOVE
  sel.unit = unit
  local selunit = sel.unit
  
  --selunit:attention()
  
  --path.append...
  --pathcosts.append...
  
  --Check movement range.
  local mcells = g.manrange(selunit.x, selunit.y, world.map.w, world.map.h, 0, selunit.movesleft)
  --Iterate over the Manhattan circle cells.
  for i,xy in pairs(mcells) do
    --check A* path to cell
    local destination = world.grid[xy[1]][xy[2]]
    local cell = world.map.layers.Mrange:getCell(xy[1], xy[2])
    -- Destination conditions:
    -- Cell is empty, or occupied by self.
    if not destination.unit or destination.unit == selunit then
      -- Set a movement range tile, store for later retrieval and clearance.
      cell:setTile(world.map.tilesets.MrangeSet:getTile(14))
      sel.mrangetiles[xy] = cell
    -- Cell is occupied by a boardable unit. (Allied boardables don't count because they remove control.)
  elseif g.hasKeys(destination.unit, {"BOARDABLE", selunit.NAME})
  and (destination.unit.team == selunit.team)
  and (#destination.unit.boardedunits <= destination.unit.BOARDCAP) then
      -- Set a boardable range tile, store for later retrieval and clearance.
      cell:setTile(world.map.tilesets.MrangeSet:getTile(14)) --need it the same for now because of logiccc.
      sel.boardabletiles[xy] = cell
    -- Allow ONLY PASSAGE for units of the same or allied teams.
    elseif destination.unit.team == selunit.team then --or ally
      cell:setTile(world.map.tilesets.MrangeSet:getTile(15))
      sel.passagetiles[xy] = cell
    end
  end
  
-- HOW TO DO MOVE TILES
--blue: valid destination
--green: allows passage only (allies)
--blue: allows passage and boarding (valid destination); show boarding arrow (and full arrow if full)
--grey: not enough fuel
--black: terrain causes this tile to cost too much
--(red): blocked by enemy (helps identify spaces that will open up if the enemy is removed)
-- use the same tile but colour it programmatically.
-- then use arrays to check identity instead of getting the tileID.

--dai senryaku: units boarded into transports cannot be unloaded in the same turn. when they unload they can immediately take a full move.
--me probably: they can unload in the same turn, as the unit keeps track of its remaining moves, and Unload defers to these.
  
  --Possible you could just cut the below logic into the above.
  
  -- Check attack range (if unit has weapons).
  -- Iterate over weapons.
  for i,wep in ipairs(selunit.weps) do
    -- Iterate over the movement range cells.
    for xy,v in pairs(sel.mrangetiles) do
      -- Proceed if weapon is direct, or cell is the starting location (for indirect weapons).
      if wep.DIRECT or (xy[1] == selunit.x and xy[2] == selunit.y) then
        -- New table for targets from this cell. One for each valid movement cell.
        world.grid[xy[1]][xy[2]].targets = {}
        -- Get the attack range from the movement cell.
        local acells = g.manrange(xy[1], xy[2], world.map.w, world.map.h, wep.MINRANGE, wep.MAXRANGE)
        -- Iterate over attack range cells.
        for i,vec in pairs(acells) do
          -- Tile cell with an attack range tile.
          local cell = world.map.layers.Arange:getCell(vec[1], vec[2])
          cell:setTile(world.map.tilesets.ArangeSet:getTile(16))
          sel.arangetiles[vec] = cell
          -- Get target and add it to the table.
          local target = world.grid[vec[1]][vec[2]].unit
          if target and (target.team ~= selunit.team) then --or ally
            table.insert(world.grid[xy[1]][xy[2]].targets, target)
          end
        end
      end
    end
  end
  
  --movedisplay.show()...
end

function f.move(world)
  local sel = world.selection
  local selunit = sel.unit
  
  -- Stop if the unit doesn't belong to you. You can select it, but that's it.
  if selunit.team ~= sel.player then
    return
  end
  
  local cur = world.cursor.actor
  local x = g.short(cur:getX())
  local y = g.short(cur:getY())
  
  --Get the cell under the cursor in the range layer.
  local tile = world.map.layers.Mrange:getCell(x, y):getTile()
  --Stop if there's no tile there, or there is a tile but it's not a movement tile.
  --In that order, because if it is nil then you can't call a method on it.
  if not tile or tile:getId() ~= 14 then
    return
  end
  
  --Now move the unit.
  sel.state = world.states.ACT
  selunit:move(x, y)
  
  --Clearing range tiles.
  for i,cell in pairs(sel.mrangetiles) do
    cell:setTile(nil)
  end
  for i,cell in pairs(sel.boardabletiles) do
    cell:setTile(nil)
  end
  for i,cell in pairs(sel.passagetiles) do
    cell:setTile(nil)
  end
  for i,cell in pairs(sel.arangetiles) do
    cell:setTile(nil)
  end
  
  -- Evaluate and show available actions.
  
  -- Board:
  -- If on boardable unit, show board. Otherwise, evaluate the other actions.
  if g.hasVector2key(sel.boardabletiles, {x,y}) then
    showaction(world.acts.Board)
  else
    -- Attack:
    local targets = world.grid[x][y].targets
    if targets and (#targets > 0) then
      showaction(world.acts.Attack)
    end
    
    --if supplyable allies in range, show supply.
    --if on capturable building, show capture.
    
    -- Unload:
    --(may want to check terrain - be a bit silly if tanks try to unload in the sea and just have to cancel.)
    if selunit.BOARDABLE and (#selunit.boardedunits > 0) then
      showaction(world.acts.Unload)
    end
    
    showaction(world.acts.Wait)
  end
  
end

function f.target(world)
  --Lookup the cursor position in the unit list to return any unit there, same as for selection.
  --Need to check if the target is valid too; maybe targets knows, or you'll have to check again.
  local cur = world.cursor.actor
  local x = g.short(cur:getX())
  local y = g.short(cur:getY())
  local target = world.grid[x][y].unit
  
  --Stop if there's no unit.
  if not target then return end
  
  --Attack target with index of selected weapon, accounting for terrain defence.
  --Obviously weapon selection doesn't happen right now so it's locked to 1.
  --Terrain is also locked.
  local sel = world.selection
  local selunit = sel.unit
  selunit:battle(target, 1, 0)
  --Check if the target is alive. We will try to counterattack with the first available weapon.
  if target then
    local counterweps = target:validweps(selunit, false)
    if #counterweps > 0 then
      target:battle(selunit, counterweps[1], 0)
    end
  end
  --Now check if the attacker is alive (could have died from the counterattack). Will then try to wait.
  if selunit then
    selunit:wait()
  end
  --Consider this: a World object?? With getters and setters for states for example. All very neat.
  
  --Reset state.
  f.undoselect(world)
end

function f.undoselect(world)
  local sel = world.selection
  
  --Clearing range tiles (and table) permanently, along with targets.
  --Having selection modify a state that isn't in world.selection is probably a bad idea, because it's confusing.
  --Maybe it'd be better to have a separate 2D array; world.selection.targetsgrid.
  for xy,cell in pairs(sel.mrangetiles) do
    cell:setTile(nil)
    world.grid[xy[1]][xy[2]].targets = nil
  end
  sel.mrangetiles = {} --Hope this frees the memory.
  
  for xy,cell in pairs(sel.boardabletiles) do
    cell:setTile(nil)
  end
  sel.boardabletiles = {}
  
  for i,cell in pairs(sel.passagetiles) do
    cell:setTile(nil)
  end
  sel.passagetiles = {}
  
  for i,cell in pairs(sel.arangetiles) do
    cell:setTile(nil)
  end
  sel.arangetiles = {}
  
  --Permanently clear selection.
  sel.state = world.states.DEFAULT
  sel.unit = nil
end

function f.undomove(world)
  local sel = world.selection
  local selunit = sel.unit
  
  --Re-setting range tiles.
  for i,cell in pairs(sel.mrangetiles) do
    cell:setTile(world.map.tilesets.MrangeSet:getTile(14))
  end
  for i,cell in pairs(sel.boardabletiles) do
    cell:setTile(world.map.tilesets.MrangeSet:getTile(14))
  end
  for i,cell in pairs(sel.passagetiles) do
    cell:setTile(world.map.tilesets.MrangeSet:getTile(15))
  end
  for i,cell in pairs(sel.arangetiles) do
    cell:setTile(world.map.tilesets.ArangeSet:getTile(16))
  end
  
  --Move the unit back.
  sel.state = world.states.MOVE
  selunit:snapback()
  
  --Hide actions.
  clearactions()
end

function f.undoattack(world)
  local sel = world.selection
  print("undo target")
  sel.state = world.states.ACT
end

--Divide these functions into (at least) two: one modifying or cancelling the previous state, and one setting new state.
--Otherwise I think you are copypasting code.

return f