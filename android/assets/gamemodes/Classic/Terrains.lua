require "class"
local g = require "Globals"
local MT = g.MOVETYPES
local units = require "Units"

-- This doesn't hold anything permanently. It's used to help push statics into classes, then wiped.
local statics = {}

local u = {}  -- Public. Contains the terrains, and an array listing them in order.
u.terrains = {}
local ter = u.terrains

--------------------
-- Static terrain --
--------------------

ter.SEA = {
  NAME = "Sea",
  ID = 1,
  PATH = "sea.png",
  DEFENCE = 0,
  MOVECOSTS = {
    [MT.INF] = nil,
    [MT.MECH] = nil,
    [MT.TYRE] = nil,
    [MT.TRACK] = nil,
    [MT.AIR] = 1,
    [MT.SHIP] = 1,
    [MT.LANDER] = 1
  }
}

ter.REEF = {
  NAME = "Reef",
  ID = 2,
  PATH = "reef.png",
  DEFENCE = 0,
  MOVECOSTS = {
    [MT.INF] = nil,
    [MT.MECH] = nil,
    [MT.TYRE] = nil,
    [MT.TRACK] = nil,
    [MT.AIR] = 1,
    [MT.SHIP] = 2,
    [MT.LANDER] = 2
  }
}

ter.ROAD = {
  NAME = "Road",
  ID = 3,
  PATH = "road.png",
  DEFENCE = 0,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 1,
    [MT.TRACK] = 1,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  }
}

ter.PLAIN = {
  NAME = "Plain",
  ID = 4,
  PATH = "plain.png",
  DEFENCE = 1,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 2,
    [MT.TRACK] = 1,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  }
}

ter.FOREST = {
  NAME = "Forest",
  ID = 5,
  PATH = "forest.png",
  DEFENCE = 2,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 3,
    [MT.TRACK] = 2,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  }
}

ter.MOUNTAIN = {
  NAME = "Mountain",
  ID = 6,
  PATH = "mountain.png",
  DEFENCE = 4,
  MOVECOSTS = {
    [MT.INF] = 2,
    [MT.MECH] = 1,
    [MT.TYRE] = nil,
    [MT.TRACK] = nil,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  }
}

ter.RIVER = {
  NAME = "River",
  ID = 7,
  PATH = "river.png",
  DEFENCE = 0,
  MOVECOSTS = {
    [MT.INF] = 2,
    [MT.MECH] = 1,
    [MT.TYRE] = nil,
    [MT.TRACK] = nil,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  }
}

ter.SHOAL = {
  NAME = "Shoal",
  ID = 8,
  PATH = "shoal.png",
  DEFENCE = 0,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 2,
    [MT.TRACK] = 1,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = 1
  }
}

----------------
-- Properties --
----------------

local MAX_CAPSTRENGTH = 10

local Property = class()
function Property:init(x, y, teamID)
  self:resetCap()
  self.x = x
  self.y = y
  self.team = teamID
end

function Property:partialCapture(unit)
  self.capStrength = self.capStrength - unit:getHp()
  if self.capStrength <= 0 then
    self:capture(unit.team)
  end
end

function Property:setCap(x)
  self.capStrength = x
end

function Property:resetCap()
  self.capStrength = MAX_CAPSTRENGTH
end

function Property:capture(team)
  --switch sprite
  self:resetCap()
  self.team = team
end

ter.Headquarters = class(Property)
statics = {
  NAME = "HQ",
  CLASS = ter.Headquarters,
  ID = 9,
  PATH = "hq_red.png",
  DEFENCE = 4,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 1,
    [MT.TRACK] = 1,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  },
  IS_PROPERTY = true,
  REPAIRS_UNITS = units.GROUND_UNITS
}
g.addPairs(ter.Headquarters, statics)

ter.City = class(Property)
statics = {
  NAME = "City",
  CLASS = ter.City,
  ID = 10,
  PATH = "city_neutral.png",
  DEFENCE = 3,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 1,
    [MT.TRACK] = 1,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  },
  IS_PROPERTY = true,
  REPAIRS_UNITS = units.GROUND_UNITS
}
g.addPairs(ter.City, statics)

ter.Factory = class(Property)
statics = {
  NAME = "Factory",
  CLASS = ter.Factory,
  ID = 11,
  PATH = "factory_neutral.png",
  DEFENCE = 3,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 1,
    [MT.TRACK] = 1,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  },
  IS_PROPERTY = true,
  REPAIRS_UNITS = units.GROUND_UNITS,
  UNITS_DEPLOYABLE = units.GROUND_UNITS
}
g.addPairs(ter.Factory, statics)

ter.Port = class(Property)
statics = {
  NAME = "Port",
  CLASS = ter.Port,
  ID = 12,
  PATH = "port_neutral.png",
  DEFENCE = 3,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 1,
    [MT.TRACK] = 1,
    [MT.AIR] = 1,
    [MT.SHIP] = 1,
    [MT.LANDER] = 1
  },
  IS_PROPERTY = true,
  REPAIRS_UNITS = units.SEA_UNITS,
  UNITS_DEPLOYABLE = units.SEA_UNITS
}
g.addPairs(ter.Port, statics)

ter.Airfield = class(Property)
statics = {
  NAME = "Airfield",
  CLASS = ter.Airfield,
  ID = 13,
  PATH = "airfield_neutral.png",
  DEFENCE = 3,
  MOVECOSTS = {
    [MT.INF] = 1,
    [MT.MECH] = 1,
    [MT.TYRE] = 1,
    [MT.TRACK] = 1,
    [MT.AIR] = 1,
    [MT.SHIP] = nil,
    [MT.LANDER] = nil
  },
  IS_PROPERTY = true,
  REPAIRS_UNITS = units.AIR_UNITS,
  UNITS_DEPLOYABLE = {
    --#notallairunits
  }
}
g.addPairs(ter.Airfield, statics)

u.terrainList = {
  ter.SEA,
  ter.REEF,
  ter.ROAD,
  ter.PLAIN,
  ter.FOREST,
  ter.MOUNTAIN,
  ter.RIVER,
  ter.SHOAL,
  ter.Headquarters,
  ter.City,
  ter.Factory,
  ter.Port,
  ter.Airfield
}

return u