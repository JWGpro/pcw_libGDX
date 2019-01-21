require "class"
local g = require "Globals"

local Command = class()
--function Command:init(args) end
--function Command:execute() end
--function Command:undo() end

local u = {}

-- A command should hold as instance vars, the minimum data necessary to do and undo ("store") the command.
-- As for imperative statements, it should defer as much as possible to the receiver (i.e. just a method call).

u.MoveCommand = class(Command)
function u.MoveCommand:init(unit, dest)
  self.NAME = "Move"
  self.unit = unit
  self.startpos = unit.pos
  self.dest = dest
  self:execute()
end
function u.MoveCommand:execute()
  -- Moves unit to destination.
  self.unit:move(self.dest, 1)
end
function u.MoveCommand:undo()
  -- Moves unit back to the start.
  self.unit:move(self.startpos, -1)
end

-- Everything below is action commands.

u.WaitCommand = class(Command)
function u.WaitCommand:init(unit)
  self.NAME = "Wait"
  self.unit = unit
  self:execute()
end
function u.WaitCommand:execute()
  self.unit:wait()
end
function u.WaitCommand:undo()
  self.unit:unwait()
end

u.AttackCommand = class(Command)
function u.AttackCommand:init(unit, wepindex, target)
  self.NAME = "Attack"
  self.unit = unit
  self.unitHp = unit.hp
  self.unitWI = wepindex
  self.target = target
  self.targetHp = target.hp
  self.targetwep = target.weps[g.tryKeys(target:validweps(target.pos, unit, false), {1})]  -- Gets the first valid wep (not index) from target.
  if self.targetwep then
    self.twepammo = self.targetwep.ammo
  end
  self:execute()
end
function u.AttackCommand:execute()
  self.unit:battle(self.target, self.unitWI)
  self.unit:wait()
end
function u.AttackCommand:undo()
  self.unit.weps[self.unitWI]:addammo(1)
  -- We know that unit fired, but how do you know if target fired? Have to check nil here, because you can't do "nil < nil".
  if (self.twepammo ~= nil) and (self.targetwep.ammo < self.twepammo) then
    self.targetwep:addammo(1)
  end
  self.unit:setHp(self.unitHp)
  self.target:setHp(self.targetHp)
  self.unit:unwait()
end

u.CaptureCommand = class(Command)
function u.CaptureCommand:init(unit, property)
  self.NAME = "Capture"
  self.unit = unit
  self.property = property
  self.propertyCap = property.capStrength
  self:execute()
end
function u.CaptureCommand:execute()
  self.property:partialCapture(self.unit)
  self.unit:wait()
end
function u.CaptureCommand:undo()
  self.property:setCap(self.propertyCap)
  self.unit:unwait()
end

u.SupplyCommand = class(Command)
function u.SupplyCommand:init(unit, targets)
  self.NAME = "Supply"
  self.unit = unit
  self.targets = targets
  --for each target getSupply()
  self:execute()
end
function u.SupplyCommand:execute()
  for _,target in pairs(self.targets) do
    target:resupply()
  end
  self.unit:wait()
end
function u.SupplyCommand:undo()
  --for each target setSupply(supplies)
  self.unit:unwait()
end

u.BuildCommand = class(Command)
function u.BuildCommand:init(building, unit)
  -- Only done by a building.
  self.NAME = "Build"
  self.source = building
  self.product = unit
--  self.money
  self:execute()
end
function u.BuildCommand:execute()
  self.building:build(self.unit)
end
function u.BuildCommand:undo()
  --no more unit
end

u.DeployCommand = class(Command)
function u.DeployCommand:init(unit, cargo)
  -- This is how units like aircraft carriers do it. The deployed unit stays inside the transport until an unload command.
  self.NAME = "Deploy"
  self.unit = unit
  self.cargo = cargo
--  self.money
  self:execute()
end
function u.DeployCommand:execute()
  self.unit:build(self.cargo)
end
function u.DeployCommand:undo()
  --no more unit. maybe die()
end

u.BoardCommand = class(Command)
function u.BoardCommand:init(cargo, transport)
  self.NAME = "Board"
  self.cargo = cargo
  self.transport = transport
  self:execute()
end
function u.BoardCommand:execute()
  -- This is one case where the acting unit does not wait afterwards; it can be transported, unloaded and moved again.
  self.cargo:board(self.transport)
  table.insert(self.transport.boardedunits, self.cargo)  -- Will always go to the end.
end
function u.BoardCommand:undo()
  self.cargo:disembark(self.transport)
  table.remove(self.transport.boardedunits)  -- Since the new cargo will always be at the end.
end

u.UnloadCommand = class(Command)
function u.UnloadCommand:init(transport, cargo)
  self.NAME = "Unload"
  self.transport = transport
  self.cargo = cargo
  self.boardnumber = transport:getCargoNumber(cargo)  -- Remembers where the cargo was loaded in case of undo.
  self:execute()
end
function u.UnloadCommand:execute()
  -- Unloads the cargo. The caller of this command (i.e. World) will then select the cargo.
  self.cargo:disembark(self.transport)
  table.remove(self.transport.boardedunits, self.boardnumber)
end
function u.UnloadCommand:undo()
  -- Puts the cargo back in the transport (where it used to be).
  self.cargo:board(self.transport)
  table.insert(self.transport.boardedunits, self.boardnumber, self.cargo)
end

u.JoinCommand = class(Command)
function u.JoinCommand:init(unit)
  self.NAME = "Join"
  self.unit = unit
  self:execute()
end
function u.JoinCommand:execute()
  self.unit:join()
end
function u.JoinCommand:undo()
  --separate
end

u.HoldCommand = class(Command)
function u.HoldCommand:init()
  self.NAME = "Hold"
end
function u.HoldCommand:execute()
  --
end
function u.HoldCommand:undo()
  --
end


--   > Statics
-- You will not have static commands here.

-- Could bind inputs to not commands, but "controls". "Select" does select/move/target for example. But those are distinct commands.
-- "fullHistory" should only contain full moves; GameMove objects.
-- When you want to get the current move to cancel the most recent command, it's just held in a var and committed to fullHistory on completion.

-- Because ultimately, what do you want "command" for?
--  > Control binding.
--  > Undo within move.
--  > Undo last move. (but later, if at all - might not be necessary.)
--  > Store move history.
--  > AI/network moves.
-- But these may be implemented differently.
-- Control binding already seems simple enough. You wouldn't need to instantiate any objects to do that.
-- So start with the AI moves. Remember how replays don't show everything?

-- A move could be a set of commands. Rewind one step, and the whole move is undone.
-- Keeping a separate command object structure would still be useful for undo-within-move though.

u.GameMove = class(Command)
function u.GameMove:init(moveCommand, actionCommand)
  -- This is purely game-facing; for replays, networking, AI, etc.
  -- Three components: a unit to act on, a destination to go to, and an action to perform there.
  -- Though at the moment, the "unit" component isn't used as each command holds a reference to the unit anyway.
  self.moveCommand = moveCommand
  self.actionCommand = actionCommand
  self.NAME = actionCommand.NAME
end
function u.GameMove:execute()
  self.moveCommand:execute()
  queue(function() 
      self.actionCommand:execute()
    end)
end
function u.GameMove:undo()
  -- Undo in the reverse order (it matters).
  self.actionCommand:undo()
  self.moveCommand:undo()
end

-- Other commands.

u.TurnEnd = class(Command)
function u.TurnEnd:init(world, units)
  self.NAME = "TurnEnd"
  self.world = world
  self.units = units
  self.states = {}
  -- Storing (living) unit states for undo.
  for k,unit in ipairs(self.units) do
    if not unit:isDead() then
      self.states[k] = {unit.movesleft, unit.canOrder}
    end
  end
  self:execute()
end
function u.TurnEnd:execute()
  -- Restore the units of the current player.
  for k,_ in pairs(self.states) do
    local unit = self.units[k]
    unit:restore()
  end
  -- Cycle control.
  self.world:cyclePlayer(1)
end
function u.TurnEnd:undo()
  -- Give back control.
  self.world:cyclePlayer(-1)
  -- Reset the states of the units.
  for k,vals in pairs(self.states) do
    local unit = self.units[k]
    -- movesleft.
    unit.movesleft = vals[1]
    if not vals[2] then
      -- wait() the unit again, if it was waited at the turn's end.
      unit:wait()
    end
  end
end


return u