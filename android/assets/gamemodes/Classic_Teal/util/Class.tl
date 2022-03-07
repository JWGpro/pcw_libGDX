local record Class
    -- setup: function()
    -- instantiate: function()
    _base: Class
    new: function(Class, ...: any): Class
end
function Class.setup(newclass: table, base: table)
    base = base or (Class as table)
    -- For setting up new classes already created as records.
    -- TODO: Refactor to use generics?

    -- Our new class is a shallow copy of its base class.
    -- This is a more memory-heavy inheritance which includes metamethods.
    for k, v in pairs(base) do
        newclass[k] = v
    end
    newclass._base = base

    -- Class:instantiate() sets an object's metatable to its class.
    -- So the class __index will point to itself for method lookup.
    newclass.__index = newclass

    -- In this implementation, the class' metatable only holds __call.
    -- __index-based inheritance isn't necessary due to the method copies.
    setmetatable(newclass, {
        __call = function(calledclass: Class, ...): table
            -- calledclass == newclass here.
            -- We use calledclass, typed as Class, because it defines .new.
            local obj: table = {}
            setmetatable(obj, calledclass as metatable<table>)
            calledclass.new(obj as Class, ...)
            return obj
        end
    } as metatable<table>)
end
function Class:new(...)
    error("__call was called (e.g. `local x = Class(y, z)`) on a class with no .new method. Define one for that class!")
end
function Class:super(...)
    local superclass = self._base  -- self will be the new object.
    superclass.new(self, ...)
end
Class.setup(Class as table)

return Class