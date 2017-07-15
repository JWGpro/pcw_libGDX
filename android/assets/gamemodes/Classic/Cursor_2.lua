Cursor = {}
Cursor.__index = Cursor

function Cursor.new()
  local self = setmetatable({}, Cursor)
  self.value = init
  return self
end

function Cursor:set_value(newval)
  self.value = newval
end

function Cursor:get_value()
  return self.value
end

function Cursor.zoomer()
  camera.zoom = 20
end
