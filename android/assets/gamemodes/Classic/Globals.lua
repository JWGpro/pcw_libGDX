local g = {}

local cellsize = nil
function g.setCellsize(x)
  cellsize = x
end
function g.getCellsize()
  return cellsize
end

function g.snap(x)
  --Snaps a "long" coordinate onto the grid of cellsize-d cells.
  --"Long" coordinates.
  local coord = cellsize * math.floor(x / cellsize)
  return coord
end

function g.long(x)
  --Upscales a "short" grid coordinate into a "long" coordinate, e.g. for placing in the stage.
  --"Long" coordinates.
  local coord = cellsize * x
  return coord
end

function g.short(x)
  --Downscales a "long" coordinate to a "short" grid coordinate, e.g. for human-readable display.
  --"Short" coordinates.
  local coord = math.floor(x / cellsize)
  return coord
end

function g.mandist(x, y)
  --"Manhattan distance" of a vector.
	--Takes a vector, gets the absolute, returns Manhattan length.
	--Most appropriately used with short coordinates rather than long.
  local dist = math.floor(math.abs(x) + math.abs(y))
  return dist
end

function g.clampMin(n, min)
  if n < min then
    return min
  else
    return n
  end
end

function g.clampMax(n, max)
  if n > max then
    return max
  else
    return n
  end
end

function g.manrange(startX, startY, mapw, maph, minrange, maxrange)
  --Returns the Manhattan or Taxicab "circle" range from a starting x/y, clamping within a map w/h, taking into account minimum range.
  --Used to get ranges, e.g. for movement and attack.
  --The x and y coordinates of the map may be different, but this function assumes the origin is always 0,0.
  local cells = {}
  
  --Sets the initial x bounds to between +/- maxrange (clamped within the map).
  local minX = g.clampMin(startX - maxrange, 0)
  local maxX = g.clampMax(startX + maxrange, mapw - 1)

  for x=minX,maxX do
    local xr = math.abs(startX - x)
    local yrange = maxrange - xr
    --Sets the y bounds to whatever is left of the range after traversing x (again clamped within the map).
    local minY = g.clampMin(startY - yrange, 0)
    local maxY = g.clampMax(startY + yrange, maph - 1)
    for y=minY,maxY do
      local yr = math.abs(startY - y)
      --Proceed if Manhattan distance >= minrange.
      if (xr + yr) >= minrange then
        --Store the coordinates of the valid cell.
        table.insert(cells, {x,y})
      end
    end
  end
  return cells
end

return g