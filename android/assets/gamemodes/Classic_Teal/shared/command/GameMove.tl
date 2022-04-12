local MoveCommand = require("shared/command/MoveCommand")
local Command = require("shared/command/Command")

local record GameMove
    name: string
    moveCommand: MoveCommand
    actionCommand: Command

    undo: function(GameMove)
    execute: function(GameMove)
    metamethod __call: function(GameMove, MoveCommand, Command): GameMove
end

return GameMove