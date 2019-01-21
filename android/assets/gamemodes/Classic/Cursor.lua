require "class"
local assets = require "Assets"
local g = require "Globals"

local u = {}

u.Cursor = class()
function u.Cursor:init(java)
  self.actor = java:newActor(true)
  local playmodes = java:getAnimationPlayModes()
  self.actor:animate(java:getAsset(assets.TextureAtlas.ANIMS), "cursoridle", 0.5, playmodes.LOOP)
  self.actor:setPosition(0, 0)
end

return u