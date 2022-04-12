-- Declaration of assets to be loaded by the LibGDX AssetManager.
-- Assets are grouped into tables named according to type:
--  Skin
--  Texture
--  TextureAtlas
--  Music
--  Sound
--  ParticleEffect
--  Pixmap
--  BitmapFont

local u: {string:{string:string}} = {}

u.Skin = {
  DEFAULT = "PCW/menuskins/Glassy/glassy-ui.json"
}

u.Texture = {
  INF_RED_1 = "PCW/unitAssets/Default/inf_red_1.png",
  INF_RED_2 = "PCW/unitAssets/Default/inf_red_2.png",
  INF_BLUE_1 = "PCW/unitAssets/Default/inf_blue_1.png",
  INF_BLUE_2 = "PCW/unitAssets/Default/inf_blue_2.png",
  APC_RED = "PCW/unitAssets/Default/apc_red.png"
}

u.TextureAtlas = {
  ANIMS = "PCW/uiAssets/Default/anims/anims.atlas"
}

u.Sound = {
  FIRE = "PCW/sfx/fire.ogg",
  DAMAGE = "PCW/sfx/damage.ogg"
}

return u
