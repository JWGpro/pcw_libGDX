-- This is a copy of the Infantry class after I realised that I could not achieve what I wanted by returning the Java MapActor object directly, attempting to store fields inside of it rather than in a Lua object.

Infantry = {}
Infantry.__index = Infantry

function Infantry.new(gamescreen, cellsize, x, y)
  
  local sprite = "PCW/unit_sprites/Default/inf_red_1.png"
  local fields = {}
  fields.hp = 100
  fields.wepname = "rifle"
  
  local actor = gamescreen:addLuaActor(sprite, 1.0, fields, cellsize)
  actor:setPosition(x, y)
  
  return actor
end

-- Methods for every interaction.
-- Damage calculation methods for each unit, since you have the UAV.
