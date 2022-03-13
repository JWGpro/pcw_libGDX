-- TODO: Refactor using a real test framework.

local Class = require("util/Class")


-- Unit

local record Unit
    x: number
    y: number
    -- _new: function(Class): Class
    -- deduct: function(Unit)
    -- add: function(Unit)
    metamethod __call: function(Unit, number, number): Unit
end
Class.setup(Unit as table)
function Unit:_new(x: number, y: number)
    self.x = x
    self.y = y
end
function Unit:deduct()
    self.x = self.x - 1
end
function Unit:add()
    self.x = self.x + 2
end
function Unit:__tostring(): string
    return self.x .. "," .. self.y
end


-- Infantry

local record Infantry
    z: number

    x: number
    y: number
    -- deduct: function(Infantry)
    add: function(Infantry)
    -- shoot: function(Infantry)
    metamethod __call: function(Infantry, number, number, number): Infantry
    _super: function(Infantry, number, number)
end
Class.setup(Infantry as table, Unit as table)
function Infantry:_new(x: number, y: number, z: number)
    self:_super(x, y)
    self.z = z
end
function Infantry:shoot()
    self.z = self.z - 1
end
--Override
function Infantry:deduct()
    self.x = self.x - 3
end
function Infantry:__tostring(): string
    return self.x .. "," .. self.y .. "," .. self.z
end

print("Can define new class and subclass")


-- Incomplete class

local record IncompleteClass
    metamethod __call: function(IncompleteClass): IncompleteClass
end
Class.setup(IncompleteClass as table)


-- Mech

local record Mech
    z: number

    x: number
    y: number
    __tostring: function(Mech): string
    metamethod __call: function(Mech, number, number, number): Mech
    _super: function(Mech, number, number)
end
Class.setup(Mech as table, Unit as table)
function Mech:_new(x: number, y: number, z: number)
    self:_super(x, y)
    self.z = z
end
-- We want __tostring to be inherited from Unit.


-- SubInfantry (Infantry subclass)

local record SubInfantry
    x: number
    y: number
    z: number
    w: number

    __tostring: function(SubInfantry): string
    metamethod __call: function(SubInfantry, number, number, number, number): SubInfantry
    _super: function(SubInfantry, number, number, number)
end
Class.setup(SubInfantry as table, Infantry as table)
function SubInfantry:_new(x: number, y: number, z: number, w: number)
    self:_super(x, y, z)
    self.w = w
end


-- tests

local unit = Unit(32, 65)
print("Can create new class instance")
assert(unit.x == 32)
print("Initialised field correct")
unit:deduct()
assert(unit.x == 31)
unit:add()
assert(unit.x == 33)
print("Can call methods")
assert(unit:__tostring() == "33,65")
print("Class object stringified correctly:")
print(unit)

local inf = Infantry(88, 49, 12)
print("Can create new subclass instance")
assert(inf.x == 88)
print("Initialised field correct")
inf:deduct()
assert(inf.x == 85)
print("Can override inherited method")
inf:add()
assert(inf.x == 87)
print("Can call inherited method")
inf:shoot()
assert(inf.z == 11)
print("Can call extra method")
assert(inf:__tostring() == "87,49,11")
print("Subclass object stringified correctly:")
print(inf)

local callUnit = Unit(734, 43)
print("Can create new class instance via __call syntax:")
print(callUnit)

-- calls IncompleteClass(), catching error
local canDoBadThing = pcall(IncompleteClass)
assert(canDoBadThing == false)
print("Throws error when no ._new method defined on class")

local mech = Mech(38, 12, 4)
assert(mech:__tostring() == "38,12")
print("__tostring metamethod inherited from base:")
print(mech)

local subinf = SubInfantry(1, 2, 3, 4)
assert(subinf.x == 1)
assert(subinf.y == 2)
assert(subinf.z == 3)
assert(subinf.w == 4)
print("Subclass of subclass instantiated correctly from two _super() calls")
assert(subinf:__tostring() == "1,2,3")
print("__tostring metamethod re-inherited from Infantry base:")
print(subinf)