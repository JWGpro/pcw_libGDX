local InGameScreen = require("javaclassdefs/InGameScreen")
local OrthographicCamera = require("javaclassdefs/OrthographicCamera")
local Stage = require("javaclassdefs/Stage")
local TiledMap = require("javaclassdefs/TiledMap")
local FuncQueue = require("util/FuncQueue")

-- Abstract class/interface

local record IWorld
    updateCursor: function(IWorld, number, number)
    translateCamera: function(IWorld, number, number)
    metamethod __call: function(IWorld, InGameScreen, OrthographicCamera, TiledMap, string, Stage, FuncQueue): IWorld
end

return IWorld