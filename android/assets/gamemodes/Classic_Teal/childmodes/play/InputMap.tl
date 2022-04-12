local Class = require("util/Class")
local Keys = require("javaclassdefs/Keys")
local Buttons = require("javaclassdefs/Buttons")
local World = require("childmodes/play/World")

local SCROLLUP = -1
local SCROLLDOWN = 1


-- Binds inputs to methods in World.
-- TODO: Don't forget to make a list of defaults and a modifiable version.
--  Maybe the defaults are just here, and the game decides whether or not to override.
local record InputMap
    --!extends Class
    --/extends

    controls: World
    binds: {string:{number:function}}
    metamethod __call: function(InputMap): InputMap
end
Class.setup(InputMap as table)
function InputMap:_new(controls: World): InputMap
    self.controls = controls

    local b = self.binds
    
    b.keyDown = {}
    -- b.keyDown[Keys.RIGHT] = controls.cursorRight --hold...
    b.keyDown[Keys.BACK] = controls.cancelLast
    -- b.keyDown[Keys.M] = controls.menu
    b.keyDown[Keys.D] = controls.printDebugInfo
    b.keyDown[Keys.R] = controls.rangeAllOn
    b.keyDown[Keys.E] = controls.nextTurn
    b.keyDown[Keys.MINUS] = controls.replayUndo
    b.keyDown[Keys.EQUALS] = controls.replayRedo
    b.keyDown[Keys.BACKSPACE] = controls.replayResume

    b.keyUp = {}
    b.keyUp[Keys.R] = controls.cancelLast --cancels rangeAllOn

    b.touchDown = {}
    -- b.touchDown[Buttons.MIDDLE] = controls.panStart

    b.touchUp = {}
    b.touchUp[Buttons.LEFT] = controls.selectNext
    b.touchUp[Buttons.RIGHT] = controls.cancelLast
    -- b.touchUp[Buttons.MIDDLE] = controls.panStop

    b.scrolled = {}
    b.scrolled[SCROLLUP] = controls.zoomIn
    b.scrolled[SCROLLDOWN] = controls.zoomOut  
end
function InputMap:tryBind(inputType: string, inputEnumVal: number)
    -- Looks for a bound function, and executes it.
    local bind = self.binds[inputType][inputEnumVal]
    if bind then
        bind(self.controls)
    end
end

return InputMap