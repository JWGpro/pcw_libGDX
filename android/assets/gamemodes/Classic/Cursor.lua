require "class"
local g = require "Globals"

local u = {}

u.Cursor = class()
function u.Cursor:init(java)
  self.sprite = "PCW/uiAssets/Default/1.png"
  self.actor = java:addLuaActor(self.sprite, 1.0)
  self.actor:setPosition(0, 0)
end

return u