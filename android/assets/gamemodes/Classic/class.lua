-- Adapted from:  http://lua-users.org/wiki/SimpleLuaClasses

--[[
Class declarations:

A = class()
function A:init(x)
  self.x = x
end
function A:test()
  print(self.x)
end

B = class(A)
function B:init(x,y)
  A.init(self,x) --Make sure to call it like this rather than like A:init(x).
  self.y = y
end

  Instantiation:
newobj = A(3)
newobj:test()

  Using the inbuilt boolean "is_a" method:
print(leo:is_a(Animal))
print(leo:is_a(Cat))
]]--

function class(base)
   -- a new class instance
   local c = {}

   if type(base) == 'table' then
      -- our new class is a shallow copy of the base class!
      for i, v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c

   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}

   mt.__call = function(class_tbl, ...)
      local obj = {}
      setmetatable(obj, c)
      if class_tbl.init then
         class_tbl.init(obj, ...)
      end
      return obj
   end

   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do
         if m == klass then return true end
         m = m._base
      end
      return false
   end

   setmetatable(c, mt)

   return c
end