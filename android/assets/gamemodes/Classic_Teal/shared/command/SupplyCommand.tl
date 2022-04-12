local Unit = require("shared/unit/Unit")

local record SupplyCommand
    metamethod __call: function(SupplyCommand, Unit, {Unit}): SupplyCommand
end

return SupplyCommand