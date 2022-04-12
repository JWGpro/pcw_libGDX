local Unit = require("shared/unit/Unit")

local record WaitCommand
    metamethod __call: function(WaitCommand, Unit): WaitCommand
end

return WaitCommand