local Unit = require("shared/unit/Unit")

local record TurnEnd
    metamethod __call: function(TurnEnd, {Unit}, function): TurnEnd
end

return TurnEnd