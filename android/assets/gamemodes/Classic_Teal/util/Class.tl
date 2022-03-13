local func = require("util/func")

-- Excludes __index and __call
local METAMETHODS = func.setOf{
    '__add',
    '__concat',
    '__div',
    '__le',
    '__lt',
    '__mod',
    '__mul',
    '__pow',
    '__sub',
    '__tostring',
    '__unm'
}

local record Class
    _base: Class
    _new: function(Class, ...: any): Class
end
function Class.setup(newclass: table, base: table)
    base = base or (Class as table)
    -- For setting up new classes already created as records.
    -- TODO: Refactor to use generics?

    newclass._base = base
    -- Our new class copies the metamethods of its base class.
    -- (These can't be inherited via __index lookup.)
    for k, v in pairs(base) do
        if METAMETHODS[k] then
            newclass[k] = v
        end
    end
    -- Define _super() to point to the base class _new() - just not for Class.
    if base ~= (Class as table) then
        newclass._super = function(obj, ...)
            -- Temporarily set the object's class to the base...
            -- If we don't, recurisve _super() calls won't work.
            local objClass = getmetatable(obj)

            local superclass = base as Class
            setmetatable(obj, superclass as metatable<Class>)
            superclass._new(obj as Class, ...)

            setmetatable(obj, objClass)
        end
    end

    -- A new object's metatable will be its class.
    -- So the class __index will point to itself for method lookup. 
    newclass.__index = newclass

    -- Below sets a class's metatable to a base class. Same effect as above.
    -- New class points to base class methods if needed; inheritance.
    setmetatable(newclass, {
        __index = base,
        __call = function(calledclass: Class, ...): table
            -- calledclass == newclass here.
            -- We use calledclass, typed as Class, because it defines ._new.
            local obj: table = {}
            setmetatable(obj, calledclass as metatable<table>)
            calledclass._new(obj as Class, ...)
            return obj
        end
    } as metatable<table>)

    -- e.g.
    -- Class.mt.__index == Class
    -- Unit.mt.__index == Class
    -- unit.mt.__index == Unit
    -- Infantry.mt.__index == Unit
    -- infantry.mt.__index == Infantry
end
function Class:_new(...)
    error("__call was called (e.g. `local x = Class(y, z)`) on a class with no ._new method. Define one for that class!")
end
Class.setup(Class as table)

return Class