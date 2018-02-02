local g = require "Globals"

local f = {}

function f.select(world)
  --Lookup the cursor position in the unit list to return any unit there.
  local cur = world.cursor.actor
  local x = g.short(cur:getX())
  local y = g.short(cur:getY())
  --At the moment, this will return an "attempt to index nil" error if you call it beyond the bounds of the map.
  --But at some point I should have it so you can't see beyond the map anyway.
  local unit = world.units[x][y]
  
  --Select that unit.
  if unit ~= nil then
    --Set state and store unit.
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
    
    --Iterate over the map.
    --Should only go to +/- sel.movesleft...no need to check the other side of the map. Still not optimised, but less code.
    for x=0, world.map.w-1 do
      for y=0, world.map.h-1 do
        --If the cell is <= sel.movesleft away,
        --Do an A* search, and if the path is <= sel.movesleft away, place a movement range tile.
        if g.mandist(sel.startX - x, sel.startY - y) <= sel.movesleft then
          --Set a movement range tile.
          local cell = world.map.layers.range:getCell(x, y)
          cell:setTile(world.map.tilesets.rangeSet:getTile(14))
          table.insert(sel.rangetiles, cell)
        end
      end
    end
    
    --movedisplay.show()...
  end
end

function f.move(world)
  local cur = world.cursor.actor
  local x = g.short(cur:getX())
  local y = g.short(cur:getY())
  
  --Get the cell under the cursor in the range layer.
  local tile = world.map.layers.range:getCell(x, y):getTile()
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
  for i,cell in pairs(sel.rangetiles) do
    cell:setTile(nil)
  end
  
  print("action state")
  sel.unit:showactions()
  
end

function f.undoselect(world)
  local sel = world.selection
  
  --Clearing range tiles (and table) permanently.
  for i,cell in pairs(sel.rangetiles) do
    cell:setTile(nil)
  end
  sel.rangetiles = {} --Hope this frees the memory.
  
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
  for i,cell in pairs(sel.rangetiles) do
    cell:setTile(world.map.tilesets.rangeSet:getTile(14))
  end
  
  sel.state = world.states.MOVE
  sel.unit:move(sel.startX, sel.startY)
end


return f