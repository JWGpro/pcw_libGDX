Cursor = {}
Cursor.__index = Cursor

function Cursor.new(gamescreen, cellsize)
  local self = setmetatable({}, Cursor)
  
  self.sprite = "PCW/ui_sprites/Default/1.png"
  self.actor = gamescreen:addLuaActor(self.sprite, 1.0, cellsize)
  
  return self
end

-- The cursor is just an animated sprite. It changes position based on mouse movement and changes animation based on state.

-- You can have a custom mouse cursor if you want too.

-- Features of the class: Texture/Sprite. InputListener.
