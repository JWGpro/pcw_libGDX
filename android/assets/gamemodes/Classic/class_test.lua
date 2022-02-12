-- TODO: Refactor using a real test framework.

require "class"

local Class = class()
print("Can define class")
function Class:init(x, y)
    self.x = x
    self.y = y
end
print("Can define class init")
function Class:__tostring()
    return self.x .. "," .. self.y
end
print("Can define class __tostring")

local Subclass = class(Class)
print("Can define subclass")
function Subclass:init(x, y, z)
    self.z = z
    Class.init(self, x, y)
end
print("Can define subclass init")

local classObject = Class(7, 23)
print("Can create class object with `Class(args)` syntax")
local subclassObject = Subclass(11, 37, 59)
print("Can create subclass object")

assert(classObject:__tostring() == "7,23")
print("Class object stringified correctly:")
print(classObject)

assert(subclassObject:__tostring() == "11,37")
print("Subclass object stringified as inherited from base:")
print(subclassObject)

assert(subclassObject.z == 59)
print("Subclass object new field correct")
