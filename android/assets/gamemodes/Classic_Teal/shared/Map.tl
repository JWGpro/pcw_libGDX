local Vector2 = require("util/Vector2")
local Unit = require("shared/unit/Unit")
local Terrain = require("shared/terrain/Terrain")
local Cursor = require("shared/Cursor")
local Class = require("util/Class")
local InGameScreen = require("javaclassdefs/InGameScreen")
local FuncQueue = require("util/FuncQueue")

local record Map
    cursor: Cursor

    snap: function(Map, number): number
    short: function(Map, number): number
    loadMap: function(Map, string)
    getCost: function(Map, Unit, Vector2): integer
    getUnit: function(Map, Vector2): Unit
    getTerrain: function(Map, Vector2): Terrain
    isValidDestination: function(Map, Vector2): boolean
    isOnGrid: function(Map, Unit): boolean
    displayRanges: function(Map, Unit)
    hideRanges: function(Map)
    clearRanges: function(Map)
    getTargets: function(Map, Vector2): {Unit}
    clearTargets: function(Map)
    isBoardable: function(Map, Vector2): boolean
    neighbourCells: function(Map, Vector2): {Vector2}
    metamethod __call: function(Map, integer, integer, InGameScreen, {string:{Unit}}, FuncQueue): Map
end
Class.setup(Map as table)
function Map:getCursorPosition(): Vector2
    -- TODO: Is this the Map's job? Or the Cursor's?...
    local cursorX = self:short(self.cursor.actor:getX())
    local cursorY = self:short(self.cursor.actor:getY())

    return Vector2(cursorX, cursorY)
end
function Map:getUnitAtCursor(): Unit
end
function Map:getTerrainAtCursor(): Terrain
end

return Map