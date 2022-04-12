local InGameScreen = require("javaclassdefs/InGameScreen")
local Skin = require("javaclassdefs/Skin")
local Stage = require("javaclassdefs/Stage")
local Map = require("shared/Map")
local Unit = require("shared/unit/Unit")

local record UnloadMenu

    clear: function(UnloadMenu)
    show: function(UnloadMenu, Unit)
    metamethod __call: function(UnloadMenu, InGameScreen, Skin, Stage, Map, function): UnloadMenu
end

return UnloadMenu