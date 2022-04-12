local Class = require("util/Class")
local Actor = require("javaclassdefs/Actor")
local Vector2 = require("util/Vector2")
local InGameScreen = require("javaclassdefs/InGameScreen")

local record Cursor
    --!extends Class
    --/extends
    actor: Actor

    getPosition: function(Cursor): Vector2
    metamethod __call: function(Cursor, InGameScreen): Cursor
end
Class.setup(Cursor as table)

return Cursor