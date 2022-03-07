local record Class
    new: function(Class, ...: any): Class
    instantiate: function(Class, table)
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

    -- Class:instantiate() sets an object's metatable to its class.
    -- So the class __index will point to itself for method lookup.
    newclass.__index = newclass

    -- In this implementation, the class' metatable only holds __call.
    -- __index-based inheritance isn't necessary due to the method copies.
    setmetatable(newclass, {
        __call = function(calledclass: Class, ...): table
            -- calledclass == newclass here.
            -- We use calledclass, typed as Class, which declares .new.
            return calledclass:new(...) as table
        end
    } as metatable<table>)
end
function Class:new()
    error("__call was called (e.g. `local x = Class(y, z)`) on a class with no .new method. Define one for that class!")
end
function Class:instantiate(newobj: table): table
    newobj = newobj or {}
    setmetatable(newobj, self)  -- self will be the calling class.
    return newobj
end
Class.setup(Class as table)

return Class