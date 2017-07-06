/*
 * Riho Peterson 2014
 * tulevik.EU
 * http://www.indiedb.com/games/office-management-101
 */
package com.pcw.game.Scripting;

import org.luaj.vm2.*;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.jse.*;

import com.badlogic.gdx.Gdx;

/*
 *  Lua script file loader and function executer
 */
public class LuaScript implements Script {

    private Globals globals = JsePlatform.standardGlobals();
    private LuaValue chunk;

    // Script exists and is otherwise loadable
    private boolean scriptFileExists;

    // Keep the file name, so it can be reloaded when needed
    public String scriptFileName;

    // Init the object and call the load method
    public LuaScript(String scriptFileName) {
        this.scriptFileName = scriptFileName;
        this.scriptFileExists = false;
        this.load(scriptFileName);
    }

    // Load the file
    public boolean load(String scriptFileName) {
        this.scriptFileName = scriptFileName;

        if (!Gdx.files.internal(scriptFileName).exists()) {
            this.scriptFileExists = false;
            return false;
        } else {
            this.scriptFileExists = true;
        }

        try {
            chunk = globals.load(Gdx.files.internal(scriptFileName).readString());
        } catch (LuaError e) {
            // If reading the file fails, then log the error to the console
            Gdx.app.log("Debug", "LUA ERROR! " + e.getMessage());
            this.scriptFileExists = false;
            return false;
        }

        // An important step. Calls to script method do not work if the chunk is not called here
        chunk.call();

        return true;
    }

    // Load the file again
    @Override
    public boolean reload() {
        return this.load(this.scriptFileName);
    }

    // Returns true if the file was loaded correctly
    @Override
    public boolean canExecute() {
        return scriptFileExists;
    }

    // Call the init function in the Lua script with the given parameters passed
    @Override
    public boolean executeInit(Object... objects) {
        return executeFunction("init", objects);
    }

    // Call a function in the Lua script with the given parameters passed
    @Override
    public boolean executeFunction(String functionName, Object... objects) {
        return executeFunctionParamsAsArray(functionName, objects);
    }

    // Now this function takes the parameters as an array instead, mostly meant so we can call other Lua script functions from Lua itself
    public boolean executeFunctionParamsAsArray(String functionName, Object[] objects) {
        if (!canExecute()) {
            return false;
        }

        LuaValue luaFunction = globals.get(functionName);

        // Check if a functions with that name exists
        if (luaFunction.isfunction()) {
            LuaValue[] parameters = new LuaValue[objects.length];

            int i = 0;
            for (Object object : objects) {
                // Convert each parameter to a form that's usable by Lua
                parameters[i] = CoerceJavaToLua.coerce(object);
                i++;
            }

            try {
                // Run the function with the converted parameters
                luaFunction.invoke(parameters);
            } catch (LuaError e) {
                // Log the error to the console if failed
                Gdx.app.log("Debug", "LUA ERROR! " + e.getMessage());
                return false;
            }
            return true;
        }
        return false;
    }

    // With this we register a Java function that we can call from the Lua script
    public void registerJavaFunction(TwoArgFunction javaFunction) {
        globals.load(javaFunction);
    }
}