require "class"
local g = require "Globals"

local u = {}  -- Public.

-- Received
local world
local java
local uistage
local map

-- Display elements
local unitLabel

local container

-- Permanent on draw
local selunit

-- Mutable
local outunit

local function update()
  --cycle outunit
  print("i dont rly do anything rite now xP")
  unitLabel:setText(outunit.NAME)
end

u.UnloadMenu = class()
function u.UnloadMenu:init(caller, gameScreen, skin, uiStage, theMap)
  world = caller
  java = gameScreen
  uistage = uiStage
  map = theMap
  
  container = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table", {}, {})
  container:setFillParent(true)
  
  --label: outunit moves left, HP, or maybe a button to bring up unit info menu
  
  unitLabel = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Label", {"CharSequence", "Skin"}, {"label", skin})
  container:add(unitLabel)
  container:row()
  
  --change unit button (no need to display all - can see APC info for that.)
  --you need to cycle between units passed by World, actually - like TargetMenu.
  --DISABLE IT if only one unit.
  
  local unitButton = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {"Unit", skin})
  java:addChangeListener(unitButton, update, nil, nil)
  container:add(unitButton)
  container:row()
  
  local confirmButton = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {"Unload", skin})
  java:addChangeListener(confirmButton, self.confirm, self, nil)
  container:add(confirmButton)
end

function u.UnloadMenu:show(selUnit)
  selunit = selUnit
  outunit = selunit.boardedunits[1]
  update()
  
  uistage:addActor(container)
end

function u.UnloadMenu:confirm()
  world:dispatchUnload(outunit)  -- World knows what happened, so it can set state.
  self:clear()
end

function u.UnloadMenu:clear()
  container:remove()
end

return u