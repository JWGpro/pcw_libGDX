local g = require "Globals"

local f = {}

local actiontable
local actionbuttons = {}
local actions = {}

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
  print("at")
  --set state to TARGET
  --show targets over targets and possibly attack range from cell too.
  --listen for a Select:TARGET command.
end
function actions.Capture(world)
  --building:capture(unit.hp)
end
function actions.Supply(world)
  --for ally in pairs(allies) do ally:resupply() end
end
function actions.Wait(world)
  local sel = world.selection
  sel.unit:burnfuel(sel.maxmoves - sel.movesleft)
  print("Fuel now: " .. sel.unit:getFuel())
  --Reset state.
  f.undoselect(world)
  clearactions()
end
function actions.Board(world)
  --board animation, set not visible, destunit:take(self)
end
function actions.Deploy(world)
  --not sure yet, probably similar to Base code.
end

function f.select(world)
  --Lookup the cursor position in the unit list to return any unit there.
  local cur = world.cursor.actor
  local x = g.short(cur:getX())
  local y = g.short(cur:getY())
  --At the moment, this will return an "attempt to index nil" error if you call it beyond the bounds of the map.
  --But at some point I should have it so you can't see beyond the map anyway.
  local unit = world.grid[x][y].unit
  
  --Stop if there's no unit.
  if unit == nil then return end
  
  --Select unit - set state and store unit.
  local sel = world.selection
  sel.state = world.states.MOVE
  sel.unit = unit
  
  --selectedunit:attention()
  --Set start location (short).
  sel.startX = g.short(unit.actor:getX())
  sel.startY = g.short(unit.actor:getY())
  --Set maximum moves in this turn.
  if unit:getFuel() >= unit:getMoves() then
    sel.maxmoves = unit:getMoves()
  else
    sel.maxmoves = unit:getFuel()
  end
  --Init remaining moves.
  sel.movesleft = sel.maxmoves
  
  --path.append...
  --pathcosts.append...
  
  --Check movement range.
  local mcells = g.manrange(sel.startX, sel.startY, world.map.w, world.map.h, 0, sel.movesleft)
  --Iterate over the Manhattan circle cells.
  for i,xy in pairs(mcells) do
    --check A* path to cell and set tile if <= sel.movesleft away
    local cell = world.map.layers.Mrange:getCell(xy[1], xy[2])
    cell:setTile(world.map.tilesets.MrangeSet:getTile(14)) --Movement range tile.
    sel.mrangetiles[xy] = cell --Store for later retrieval and clearance.
  end
  
  --By the way, if friendly units are in the way, you won't be able to stop and attack from there.
  --Possible you could just cut the below logic into the above.
  
  --Check attack range (if unit has weapons).
  if sel.unit.weps ~= nil then
    --Iterate over weapons.
    for i,wep in pairs(sel.unit.weps) do
      --Iterate over the movement range cells.
      for xy,v in pairs(sel.mrangetiles) do
        --Proceed if weapon is direct, or cell is the starting location (for indirect weapons).
        if wep.direct or (xy[1] == sel.startX and xy[2] == sel.startY) then
          --New table for targets from this cell. One for each valid movement cell.
          world.grid[xy[1]][xy[2]].targets = {}
          --Get the attack range from the movement cell.
          local acells = g.manrange(xy[1], xy[2], world.map.w, world.map.h, wep.minrange, wep.maxrange)
          --Iterate over attack range cells.
          for i,vec in pairs(acells) do
            --Tile cell.
            local cell = world.map.layers.Arange:getCell(vec[1], vec[2])
            cell:setTile(world.map.tilesets.ArangeSet:getTile(16)) --Attack range tile.
            sel.arangetiles[vec] = cell
            --Get target and add it to the table.
            local target = world.grid[vec[1]][vec[2]].unit
            if target ~= nil then
              table.insert(world.grid[xy[1]][xy[2]].targets, target)
            end
          end
        end
      end
    end
  end
  
  --movedisplay.show()...
end

function f.move(world)
  local cur = world.cursor.actor
  local x = g.short(cur:getX())
  local y = g.short(cur:getY())
  
  --Get the cell under the cursor in the range layer.
  local tile = world.map.layers.Mrange:getCell(x, y):getTile()
  --Stop if there's no tile there, or there is a tile but it's not a movement tile.
  --In that order, because if it is nil then you can't call a method on it.
  if tile == nil or tile:getId() ~= 14 then
    return
  end
  
  --Now move the unit.
  local sel = world.selection
  sel.state = world.states.ACT
  sel.unit:move(x, y)
  
  --Clearing range tiles.
  for i,cell in pairs(sel.mrangetiles) do
    cell:setTile(nil)
  end
  for i,cell in pairs(sel.arangetiles) do
    cell:setTile(nil)
  end
  
  --temporary: track moves for fuel.
  sel.movesleft = sel.movesleft - g.mandist(sel.startX - x, sel.startY - y)
  
  --Evaluate and show available actions.
  
  --Attack:
  --This assumes the unit has a weapon at all, otherwise targets will be nil and needs to be checked - but forget this for now.
  if #world.grid[x][y].targets > 0 then
    showaction(world.acts.Attack)
  end
  
  --if supplyable allies in range, show supply.
  --if on capturable building, show capture.
  
  --if on boardable unit, show board, otherwise wait. (not mutually exclusive with above.)
  if true then
    showaction(world.acts.Wait)
  end
  
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
  for i,cell in pairs(sel.arangetiles) do
    cell:setTile(nil)
  end
  sel.arangetiles = {}
  
  --Permanently clear selection.
  sel.state = world.states.DEFAULT
  sel.unit = nil
  sel.startX = nil
  sel.startY = nil
  sel.maxmoves = nil
  sel.movesleft = nil
end

function f.undomove(world)
  local sel = world.selection
  
  --Re-setting range tiles.
  for i,cell in pairs(sel.mrangetiles) do
    cell:setTile(world.map.tilesets.MrangeSet:getTile(14))
  end
  for i,cell in pairs(sel.arangetiles) do
    cell:setTile(world.map.tilesets.ArangeSet:getTile(16))
  end
  
  --Move the unit back.
  sel.state = world.states.MOVE
  sel.unit:move(sel.startX, sel.startY)
  
  --Hide actions.
  clearactions()
end

function f.undotarget(world)
  local sel = world.selection
  print("undo target")
  sel.state = world.states.ACT
end

return f