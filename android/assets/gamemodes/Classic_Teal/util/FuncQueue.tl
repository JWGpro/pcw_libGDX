local Class = require("util/Class")

-- A FIFO queue of anonymous functions holding arbitrary code.
local record FuncQueue
    --!extends Class
    --/extends

    queueList: {function}
    endtime: number
    framecount: number
    metamethod __call: function(FuncQueue): FuncQueue
end
Class.setup(FuncQueue as table)
function FuncQueue:_new()
    self.queueList = {}
    self.endtime = nil
    self.framecount = 0  -- unlikely to be useful beyond debugging.
end
function FuncQueue:queue(func: function)
    --[[
    -- Takes blocks of code in anonymous functions:
    q:queue(function()
        print(1)
        print(2)
        end)
        
    -- Something which sadly doesn't work is this:
    function FuncQueue:queuealt(code)
        table.insert(self.queueList, function() return code end)
    end
    -- Valid syntax with comma-separated statements, but they are executed immediately (before queuealt is called):
    q:queuealt(
        print(1),
        print(2)
    )
    ]]--
    table.insert(self.queueList, func)
end
function FuncQueue:shunt(func: function)
    -- Moves something to the front of the queue. Should only be for blocking.
    table.insert(self.queueList, 1, func)
end
function FuncQueue:blockWhile(eval: function)
    if eval() then
        self:shunt(function()
            self:blockWhile(eval)
        end)
    end
end
function FuncQueue:blockWhile(eval: function)
    if eval() then
        self:shunt(function()
            self:blockWhile(eval)
        end)
    end
end
function FuncQueue:queueBlockWhile(eval: function)
    --[[
    -- Delays execution of queued functions if the passed function evaluates to true.
    -- e.g.:
    q:queueBlockWhile(function()
            return self:isMoving()
            end)
    -- Of course, with the above format, you can just "return not self:isMoving()" if desired.
    -- you'd think there'd be a cleaner way to defer evaluation of an arbitrary condition...
    ]]--
    self:queue(function()
        self:blockWhile(eval)
    end)
end
function FuncQueue:blockFor(seconds: number)
    if seconds then
        self.endtime = os.clock() + seconds
    end
    if os.clock() < self.endtime then
        self:shunt(function()
            self:blockFor(nil)
        end)
    end
end
function FuncQueue:queueBlockFor(seconds: number)
    --[[
    -- Delays execution of queued functions for the duration passed.
    -- e.g.:
    q:queueBlockFor(1)
    ]]--
    self:queue(function()
        self:blockFor(seconds)
        end)
end
function FuncQueue:executeNext()
    -- increment the frame count
    self.framecount = self.framecount + 1
    -- Get and execute the first function (only) in the queue. Only the first for some reason...you could try executing all until reaching a blockWhile.
    if next(self.queueList) ~= nil then
        local func = table.remove(self.queueList, 1)
        func()
  end
end
function FuncQueue:__tostring(): string
    -- Print everything in the queue, although you can't print function names.
    for i,v in ipairs(self.queueList) do
        print(i,v)
    end
end

return FuncQueue