local Vector2 = require("util/Vector2")

local record Unit
    NAME: string
    BOARDABLE: boolean
    CAN_SUPPLY: boolean
    position: Vector2
    boardedUnits: {Unit}

    canMove: function(Unit): boolean
    isOrderable: function(Unit): boolean
    isWounded: function(Unit): boolean
    team: string
    getPosition: function(Unit): Vector2
end

return Unit