local Unit = require("shared/unit/Unit")

local record UnloadCommand
    metamethod __call: function(UnloadCommand, Unit, Unit): UnloadCommand
end

return UnloadCommand