Infantry = {}
Infantry.__index = Infantry

function Infantry.new(gamescreen, cellsize, x, y)
  local self = setmetatable({}, Infantry)
  
  self.sprite = "PCW/unit_sprites/Default/inf_red_1.png"
  self.actor = gamescreen:addLuaActor(self.sprite, 1.0, cellsize)
  self.actor:setPosition(x, y)
  
  self.hp = 100
  self.wepname = "rifle"
  
  return self
end

-- Methods for every interaction.
-- Damage calculation methods for each unit, since you have the UAV.
