-- This is a copy of the Infantry class before I screw around with it any further, to demonstrate a "standard" Lua class.

Infantry = {}
Infantry.__index = Infantry

function Infantry.new(gamescreen)
  local self = setmetatable({}, Infantry)
  
  self.sprite = "PCW/unit_sprites/Default/inf_red_1.png"
  self.hp = 100
  self.ammo = nil
  
  me = gamescreen:addLuaActor(self.sprite, 1.0)
--  me:setX(50.0)
--  return me
  return self
end

-- Methods for every interaction.
-- Damage calculation methods for each unit, since you have the UAV.

function Infantry:draw()
  
end

