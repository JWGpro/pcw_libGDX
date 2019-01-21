require "class"
local assets = require "Assets"
local g = require "Globals"

local u = {}  -- Public.

-- Received
local java
local map
local q

local playmodes
local vfx_actor1
local vfx_actor2

function u.init(gameScreen, theMap, queue)
  java = gameScreen
  map = theMap
  q = queue
  
  playmodes = java:getAnimationPlayModes()
  vfx_actor1 = java:newActor(false)
  vfx_actor2 = java:newActor(false)
  
  u.sfx_fire = java:getAsset(assets.Sound.FIRE)
  u.sfx_damage = java:getAsset(assets.Sound.DAMAGE)
end

function u.fire(vector)
  --enough actors for this? arg: actor number?
  --or you could allocate jobs to actors here.
  u.sfx_fire:play()
  
  q:queue(function()
      vfx_actor1:unhide()
      map:placeActor(vfx_actor1, vector)
      vfx_actor1:animate(java:getAsset(assets.TextureAtlas.ANIMS), "fire", 0.1, playmodes.NORMAL)
    end)
  q:queueBlockWhile(function()
      return vfx_actor1:isPlayingAnim()
    end)
  q:queue(function()
      vfx_actor1:hide()
    end)
end

function u.damage(vector)
  u.sfx_damage:play()
  
  --very WET
--  q:queue(function()
--      vfx_actor2:unhide()
--      map:placeActor(vfx_actor2, vector)
--      vfx_actor2:animate(java:getAsset(assets.TextureAtlas.ANIMS), "damage", 0.1, playmodes.NORMAL)
--    end)
--  q:queueBlockWhile(function()
--      return vfx_actor2:isPlayingAnim()
--    end)
--  q:queue(function()
--      vfx_actor2:hide()
--    end)
end

return u