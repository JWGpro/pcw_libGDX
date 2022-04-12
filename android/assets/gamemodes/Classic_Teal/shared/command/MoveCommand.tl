local Unit = require("shared/unit/Unit")
local Vector2 = require("util/Vector2")

local record MoveCommand
    NAME: string
    unit: Unit
    origin: Vector2
    destination: Vector2

    execute: function(MoveCommand)
    undo: function(MoveCommand)
    metamethod __call: function(MoveCommand, Unit, Vector2): MoveCommand
end

return MoveCommand