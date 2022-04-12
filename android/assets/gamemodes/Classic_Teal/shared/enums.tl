local u: {string:{string:string}} = {}

u.TEAMS = {
    NEUTRAL = "Neutral",
    RED = "Red",
    BLUE = "Blue",
    YELLOW = "Yellow",
    GREEN = "Green"
}

u.ACTS = {
    ATTACK = "Attack",
    CAPTURE = "Capture",
    SUPPLY = "Supply",
    WAIT = "Wait",
    BOARD = "Board",
    DEPLOY = "Deploy",
    UNLOAD = "Unload",
    JOIN = "Join",
    HOLD = "Hold"
}

u.MOVETYPES = {
    INF = "Infantry",
    MECH = "Mech",
    TYRE = "Tyres",
    TRACK = "Tracks",
    AIR = "Aircraft",
    SHIP = "Ship",
    LANDER = "Lander"
}

u.ARMOURS = {
    VEST = "Ballistic vest",
    L_VEH = "Soft-skinned vehicle",
    H_VEH = "Amoured vehicle",
    ERA = "Reactive armour",
    COPTER = "Helicopter armour"
}

u.AMMOTYPES = {
    RIFLE = "Rifle round",
    CAL50 = ".50 cal",
    HEAT = "HEAT",
    SABOT = "APFSDS"
}

-- local A = u.ARMOURS
-- local AMMO = u.AMMOTYPES

-- u.AMMOMOD = {
--     [AMMO.RIFLE] = {
--         [A.VEST] = 1,
--         [A.L_VEH] = 0.5,
--         [A.H_VEH] = 0.05,
--         [A.ERA] = 0.01,
--         [A.COPTER] = 0.1
--     },
--     [AMMO.CAL50] = {
--         [A.VEST] = 1,
--         [A.L_VEH] = 0.8,
--         [A.H_VEH] = 0.1,
--         [A.ERA] = 0.05,
--         [A.COPTER] = 0.25
--     },
--     [AMMO.SABOT] = {
--         [A.COPTER] = 1
--     }
-- }

return u