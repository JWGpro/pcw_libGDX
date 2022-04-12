local Class = require("util/Class")

local record Vector2
    --!extends Class
    --/extends

    x: number
    y: number
    metamethod __call: function(Vector2, number, number): Vector2
end
Class.setup(Vector2 as table)
function Vector2:_new(x: number, y: number)
  self.x = x
  self.y = y
end
function Vector2:__tostring(): string
  return self.x .. "," .. self.y
end
function Vector2:add(vec: Vector2): Vector2
  return Vector2(self.x + vec.x, self.y + vec.y)
end
function Vector2:subtract(vec: Vector2): Vector2
  return Vector2(self.x - vec.x, self.y - vec.y)
end
function Vector2:equals(vec: Vector2): boolean
  return (self.x == vec.x and self.y == vec.y)
end
function Vector2:mandist(vec: Vector2): number
  -- "Manhattan distance" to another vector.
  return math.abs(self.x - vec.x) + math.abs(self.y - vec.y)
end

return Vector2