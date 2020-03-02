require "class"
local g = require "Globals"
local units = require "Units"

local u = {}  -- Public.

-- Received
local world
local java

local menu
local unitbuttons = {}
local deployer  -- Like, the building deploying.

local function spawn(unit)
  -- Deploys the unit over deployer by calling its constructor.
  --for deployment to carriers, could immediately then load into the carrier...though init might try to set refs...
  local newunit = unit(deployer.x, deployer.y, deployer.team)
  newunit:wait()
  world:closemenus()  -- World will set the appropriate state, but it needs to know the menu was closed.
end

u.DeployMenu = class()
function u.DeployMenu:init(caller, gameScreen, skin, uiStage)
  world = caller
  java = gameScreen
  local uistage = uiStage
  
  menu = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table", {}, {})
  uistage:addActor(menu)
  menu:setFillParent(true)
  menu:top()
  menu:left()
  menu:pad(10)
  
  -- Creates buttons for all units. Will decide which ones to actually show later, depending on building.
  for i,unit in pairs(units.UNITS) do
    local button = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton", {"String", "Skin"}, {unit.NAME, skin})
    unitbuttons[unit.NAME] = button
    java:addChangeListener(button, spawn, nil, unit)
  end
  
end

function u.DeployMenu:show(dp)
  deployer = dp
  
  for i,unit in ipairs(deployer.UNITS_DEPLOYABLE) do
    --Get button.
    local button = unitbuttons[unit.NAME]
    --Add to table.
    menu:add(button)
    --Next row.
    menu:row()
  end
end

function u.DeployMenu:clear()
  deployer = nil
  menu:clearChildren()
end

return u