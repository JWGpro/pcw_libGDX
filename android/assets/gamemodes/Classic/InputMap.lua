local c = require "Commands"

local i = {}

-- If you're worried about making typos here on Commands, see "Detecting Undefined Variables".
-- Don't forget to make a list of defaults and a modifiable version.

i.keyDown = {}
i.keyDown[4] = c.Cancel --Android back button.
i.keyDown[41] = c.Menu --M
i.keyDown[44] = c.PrintCoord --P
i.keyDown[46] = c.RangeAllOn --R
i.keyDown[33] = c.NextTurn --E

i.keyUp = {}
i.keyUp[46] = c.RangeAllOff --R

i.touchDown = {}
i.touchDown[2] = c.PanStart --MMB

i.touchUp = {}
i.touchUp[0] = c.Select
i.touchUp[1] = c.Cancel --hold RMB to deselect - could be a method in Unit; deselectTimer++.
i.touchUp[2] = c.PanStop --MMB

i.scrolled = {}
i.scrolled[-1] = c.ZoomIn
i.scrolled[1] = c.ZoomOut

return i