local IWorld = require("shared/IWorld")

-- Abstract class/interface

local record IInputMap
    tryBind: function(IInputMap, string, number)
    metamethod __call: function(IInputMap, IWorld): IInputMap
end

return IInputMap