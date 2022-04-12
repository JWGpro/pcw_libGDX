local Unit = require("shared/unit/Unit")

local record BoardCommand
    metamethod __call: function(BoardCommand, Unit, Unit): BoardCommand
end

return BoardCommand