require "class"
local g = require "Globals"
local ter = require "Terrains"
local terrains = ter.terrains
local terrainlist = ter.terrainList

local u = {}  -- Public.

local java
local extdir
local uistage
local terrainset

local activetile = terrains.PLAIN
local activeteam = g.TEAMS.NEUTRAL
local atb
local tilelist

local function ImageRowTextButton(button)
  -- Takes an ImageTextButton and places the image on top of the label.
  button:clearChildren()
  button:add(button:getImage()):row()
  button:add(button:getLabel())
end

local function atbUpdate(tile)
  atb:setText(tile.NAME)
  --ALERT: DANGER: REFLECTION ON-THE-FLY: SITUATION MAJOR
  --so do on init for all in terrainset.
  local atbsprite = java:reflect("com.badlogic.gdx.scenes.scene2d.utils.TextureRegionDrawable",
    {"TextureRegion"}, {terrainset:getTile(tile.ID):getTextureRegion()})
  atb:getStyle().imageUp = atbsprite --work the texture to fit
end

local function openTileList()
  atb:remove()
  uistage:addActor(tilelist)
end

local function setActiveTile(tile)
  --gonna be different for units
  tilelist:remove()
  activetile = tile
  atbUpdate(activetile)
  uistage:addActor(atb)
end

u.TileSelectUI = class()
function u.TileSelectUI:init(gameScreen, skin, externalDir, uiStage, terrainSet)
  java = gameScreen
  extdir = externalDir
  uistage = uiStage
  terrainset = terrainSet
  
  -- Creating the terrain/unit selection list.
  tilelist = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.Table",
    {}, {})
  tilelist:setFillParent(true)
  local i = 0
  for _,terrain in ipairs(terrainlist) do
    local button = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.TextButton",
      {"String", "Skin"}, {terrain.NAME, skin})
    tilelist:add(button):width(button:getPrefWidth() * 0.5):height(button:getPrefHeight() * 0.5)
    java:addChangeListener(button, setActiveTile, terrain)
    i = i + 1
    if i == 3 then
      tilelist:row()
      i = 0
    end
  end
  
  -- Now for the active tile button.
  atb = java:reflect("com.badlogic.gdx.scenes.scene2d.ui.ImageTextButton",
    {"String", "Skin"}, {activetile.NAME, skin})
  atbUpdate(activetile)
  ImageRowTextButton(atb)
  
  --none of this works rn lol
  atb:bottom()
  atb:right()
  atb:pad(10)
  
  java:addChangeListener(atb, openTileList, nil)
  uistage:addActor(atb)
end

function u.TileSelectUI:getActiveTile()
  return activetile
end

function u.TileSelectUI:getActiveTeam()
  return activeteam
end



return u