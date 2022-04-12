# Using declaration files with Teal

https://github.com/teal-language/tl/blob/master/docs/declaration_files.md

You can use declaration files to annotate the types of third-party Lua modules (i.e. any Lua code).

Example Lua code to be imported:

```
--class.lua
local class = {}

function class.new(base)
    ...
end

return class
```

Declaration file for the above (albeit rough):

```
--class.d.tl
local record class
    new: function(class): class
end

return class
```

Teal code that imports this:

```
--test.tl
local class = require("class")
local c = class.new()

-- ...
```

The .lua and .t.dl files should have the same filename and be required via the same path, e.g. residing in the same directory.
The type check `tl check` will then refer to the .d.tl file, execution will refer to the .lua file as normal.