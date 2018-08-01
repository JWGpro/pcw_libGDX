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
-- Action commands are only ever undone via replay rewind, in combination with a move command.
-- Therefore, there's no need for any action command to store (for undo) anything covered by the move command undo (e.g. unit:snapback).

u.WaitCommand = class(Command)
-- The wait command might seem unnecessary, and appended to all action commands - but at least Board must not wait() the unit.
-- For now, the implementation here (wait and restore) is copypasted to every command that needs it, instead of storing another WaitCommand.
-- That might prove shortsighted.
function u.WaitCommand:init(unit)
  self.unit = unit
  self:execute()
end
function u.WaitCommand:execute()
  self.unit:wait()
end
function u.WaitCommand:undo()
  self.unit:restore()
end

u.AttackCommand = class(Command)
function u.AttackCommand:init(unit, wepindex, target)
  self.unit = unit
  self.unitHp = unit.hp
  self.wepindex = wepindex
  self.target = target
  self.targetHp = target.hp
  self:execute()
end
function u.AttackCommand:execute()
  self.unit:battle(self.target, self.wepindex)
  self.unit:wait()  --u can only do this if selunit is still alive!!...i think?? oh...no. the unit still has a reference.
end
function u.AttackCommand:undo()
  --restore lost ammo (for both)
  --restore lost hp (for both)
  self.unit:restore()
end

u.CaptureCommand = class(Command)
function u.CaptureCommand:init(unit, property)
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
  self.unit:restore()
end

u.SupplyCommand = class(Command)
function u.SupplyCommand:init(unit, targets)
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
  self.unit:restore()
end

u.BuildCommand = class(Command)
function u.BuildCommand:init(building, unit)
  -- Only done by a building.
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
  self.cargo = cargo
  self.transport = transport
  self:execute()
end
function u.BoardCommand:execute()
  -- This is one case where the acting unit does not wait afterwards; it can be transported, unloaded and moved again.
  self.cargo:board(self.transport)
end
function u.BoardCommand:undo()
  self.cargo:disembark(self.transport)
end

u.UnloadCommand = class(Command)
function u.UnloadCommand:init(transport, cargo)
  self.transport = transport
  self.cargo = cargo
  self:execute()
end
function u.UnloadCommand:execute()
  -- Unloads the cargo. The caller of this command (i.e. World) will then select the cargo.
  self.cargo:disembark(self.transport)
  -- No wait afterwards; free to move.
end
function u.UnloadCommand:undo()
  -- Puts the cargo back in the transport.
  --this is probs gonna change the order of the units in the transport (putting it to the back due to replay), but oh wel.
  --same with the BoardCommand which is just the reverse.
  self.cargo:board(self.transport)
  self.transport:restore() --
end

u.JoinCommand = class(Command)
function u.JoinCommand:init(unit)
  self.unit = unit
  self:execute()
end
function u.JoinCommand:execute()
  self.unit:join()
end
function u.JoinCommand:undo()
  --separate
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
end
function u.GameMove:execute()
  self.moveCommand:execute()
  self.actionCommand:execute()
end
function u.GameMove:undo()
  -- Undo in the reverse order (it matters).
  self.actionCommand:undo()
  self.moveCommand:undo()
end


return u