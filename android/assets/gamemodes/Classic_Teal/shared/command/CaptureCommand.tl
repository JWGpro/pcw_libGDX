local Unit = require("shared/unit/Unit")
local Terrain = require("shared/terrain/Terrain")

local record CaptureCommand
    metamethod __call: function(CaptureCommand, Unit, Terrain): CaptureCommand
end

return CaptureCommand