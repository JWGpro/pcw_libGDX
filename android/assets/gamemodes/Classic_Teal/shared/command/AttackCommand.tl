local Unit = require("shared/unit/Unit")

local record AttackCommand

    metamethod __call: function(AttackCommand, Unit, integer, Unit): AttackCommand
end

return AttackCommand