/*
 * Riho Peterson 2014
 * tulevik.EU
 * http://www.indiedb.com/games/office-management-101
 */
package com.pcw.game.Scripting;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.ThreeArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;

import com.badlogic.gdx.Gdx;

/*
 * ExecuteScript singleton that defines the ExecuteScript function that enables Lua scripts to call Lua functions
 * Refer to LuaJ Readme for more information http://luaj.org/luaj/README.html
 */
public final class ExecuteScript extends TwoArgFunction {

    private static ExecuteScript instance = new ExecuteScript();

    public ExecuteScript() {}

    @Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.set("ExecuteScript", new ExecuteScriptImplementation());
        return env;
    }

    public static ExecuteScript getInstance() {
        return instance;
    }

    static class ExecuteScriptImplementation extends ThreeArgFunction {
        public LuaValue call(LuaValue key, LuaValue functionName, LuaValue objects) {
            if (!key.isstring()) {
                Gdx.app.log("Debug", "The first parameter of ExecuteScript has to be a string");
                return LuaValue.valueOf(false);
            }
            if (!functionName.isstring()) {
                Gdx.app.log("Debug", "The second parameter of ExecuteScript has to be a string");
                return LuaValue.valueOf(false);
            }
            // Table is Lua's version of an array
            if (!objects.istable()) {
                Gdx.app.log("Debug", "The third parameter of ExecuteScript has to be a table");
                return LuaValue.valueOf(false);
            }
            // Convert Lua value to a table
            LuaTable luaTable = objects.checktable();
            // Construct a Java array from the table
            Object[] objectArray = new Object[luaTable.length()];
            for (int i = 0; i < luaTable.length(); i++) {
                objectArray[i] = luaTable.get(i + 1);
            }
            // Run the Lua function functionName in script file key and pass the parameters to it, convert the result to a form that Lua can use
            return LuaValue.valueOf(ScriptManager.executeFunctionParamsAsArray(key.toString(), functionName.toString(), objectArray));
        }
    }
}
