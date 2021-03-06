require "class"
local g = require "Globals"
require "Commands"

local u = {}  -- Public.

-- Received
local java

local actiontable  -- The action menu itself, a table. Always onscreen, but invisible until populated with buttons.
local actionbuttons = {}  -- The buttons.

u.ActionMenu = class()
function u.ActionMenu:init(gameScreen, skin, uiStage, actionfuncs)
  java = gameScreen
  local uistage = uiStage
  
  -- Create the actions menu.
  -- Reflection is relatively slow, so this sort of thing should be done once at the game's start.
  actiontable = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table", {}, {})
  uistage:addActor(actiontable)
  actiontable:setFillParent(true)
  actiontable:top()
  actiontable:left()
  actiontable:pad(10)
  -- For each action in the list of possible actions,
  for act,str in pairs(g.ACTS) do
    -- Create a button displaying the action string.
    local button = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {str, skin})
    -- Store button.
    actionbuttons[str] = button
    java:addChangeListener(button, actionfuncs[str], nil, nil)  -- actionfuncs reside in World right now, passed by Map.
  end
end

function u.ActionMenu:showaction(action)
  --Get button.
  local button = actionbuttons[action]
  --Add to table.
  actiontable:add(button)
  --Next row.
  actiontable:row()
end

function u.ActionMenu:clear()
  actiontable:clearChildren()
end

function u.ActionMenu:hide()
  --
end

function u.ActionMenu:show()
  --
end

return u