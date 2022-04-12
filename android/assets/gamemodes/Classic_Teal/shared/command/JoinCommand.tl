local Unit = require("shared/unit/Unit")

local record JoinCommand
    metamethod __call: function(JoinCommand, Unit): JoinCommand
end

return JoinCommand