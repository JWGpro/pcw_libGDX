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

return g