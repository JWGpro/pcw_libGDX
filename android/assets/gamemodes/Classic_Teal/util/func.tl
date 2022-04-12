local u = {}

function u.clampMin(n: number, min: number): number
  if n < min then
    return min
  else
    return n
  end
end

function u.clampMax(n: number, max: number): number
  if n > max then
    return max
  else
    return n
  end
end

function u.setOf(list: {any}): {any:boolean}
  -- Forms a searchable table from an array, with keys set to the intended values, and all values as "true".
  -- Can then search like so:
  --  local mySet = setOf{"cat", "dog", "cow"}
  --  if mySet.cat then...
  local set = {}
  for _, v in ipairs(list) do
    set[v] = true
  end
  return set
end
--[[

function g.tryKeys(table, args)
  -- Tries a sequence of keys on a given table. For example, table[unit][1].
  -- Prevents you from needing to check nil on each key.
  -- Returns the final value if all keys exist, nil if not. Could also make it return/print the index of the first nil key.
  
  -- You have to pass a valid table as the first argument.
  local check = table
  for i,v in ipairs(args) do
    if check[v] == nil then
      return nil
    end
    check = check[v]
  end
  return check
end

function g.addPairs(table, keypairs)
  -- This is simply meant to reduce repetition when adding several k,v pairs. For example:
  --  u.Infantry.NAME = "Infantry"
  --  u.Infantry.COST = 1000
  --  ...
  -- Becomes:
  --  statics = {NAME = "Infantry", COST = 1000, ...}
  --  g.addPairs(u.Infantry, statics)
  for k,v in pairs(keypairs) do
    table[k] = v
  end
end

function g.hasVector2key(table, vec)
  -- Assumes that the table's keys are entirely Vector2s, then checks them against the passed vector.
  for k,v in pairs(table) do
    if k:equals(vec) then
      return true
    else
      return false
    end
  end
end

]]

function u.cycle(tbl: {any}, check: any, direction: integer): any
  -- Takes an array-like table and returns a value relative to the position of the check.
  -- When direction == 1, cycles forwards (returning the next value). When direction == -1, cycles backwards.
  -- But values other than 1 and -1 should work too.
  for i, v in ipairs(tbl) do
    if v == check then
      -- (i + direction) gives the sought index. Modulo forces it to cycle inside the table.
      -- +1 gives Lua-valid indexes (e.g. 1-3 instead of 0-2).
      -- -1 fixes offset for Lua indexing (e.g. 0 >> #table, 1 >> 1 instead of -1 >> #table, 0 >> 1).
      local index = ((i + direction - 1) % #tbl) + 1
      return tbl[index]
    end
  end
end

--[[

function g.damageCalc(Aclass, Ahp, Awep, Dclass, Dhp, Ddef)
  -- HP is expected to be passed raw (1-100). It's converted to a float with step 0.1 (0.1, 0.2...1.0).
  local attackerstrength = math.ceil((Ahp / Aclass.MAXHP) * 10) / 10
  local defenderstrength = math.ceil((Dhp / Dclass.MAXHP) * 10) / 10
  local weapon = Aclass.WEPS[Awep]
  -- Look up the modifier for the ammo type on the defender's armour.
  local armourpenalty = g.AMMOMOD[weapon.AMMOTYPE][Dclass.ARMOUR]
  -- Terrain defences subtract 10% of damage for each star, but the effect is proportional to the defender's strength.
  local defstars
  -- And defences do not apply to air units.
  if Dclass.MOVETYPE == g.MOVETYPES.AIR then
    defstars = 0
  else
    defstars = Ddef
  end
  local terrainpenalty = (1 - (0.1 * defstars * defenderstrength))
  
  return attackerstrength * weapon.DAMAGE * armourpenalty * terrainpenalty
end

]]

return u