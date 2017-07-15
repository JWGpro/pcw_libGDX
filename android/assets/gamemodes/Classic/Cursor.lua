Cursor = {}
Cursor.__index = Cursor

function Cursor.new()
  local self = setmetatable({}, Cursor)
  -- Here is the sprite and stuff. No input handling because that's all in main.
  self.sprite = "badlogic.jpg"
  return self
end

-- LibGDX Actor methods below. Well you don't need to implement anything, because it's not an interface. Soooo....errrrrrrrrrrrrrrr
-- Say this was an Infantry unit. It would have stuff like HP and ammo, and maybe like attack() methods inherited from a Unit class.
-- What does this class need? Well...nothing really. It's just an animated sprite. It does change state...

-- The cursor is just an animated sprite. It changes position based on mouse movement and changes animation based on state.

-- For now let's try drawing the badlogic thing.
-- Err...Texture?

-- Getters and setters...just think about it. Methods for every interaction actually; see below.
-- Damage calculation methods for each unit, since you have the UAV.

-- Let's see all the stuff that a class needs to have.
-- Maybe only the PC version needs a cursor. Nah, doesn't need it. You can have a custom mouse cursor if you want though.
-- Err...keyboard controls do need a cursor though.

--pass Actor as argument and then modify uit???
--no,...nedd to CREATE instances within lua`
--cursor = new java:Actor(), that is how you make an object. can you modify the methods externally so it doesn't need passing back?

-- Features of the class: Texture/Sprite. InputListener.

function Cursor:draw()
  
end

