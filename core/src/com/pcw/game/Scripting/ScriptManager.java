/*
 * Riho Peterson 2014
 * tulevik.EU
 * http://www.indiedb.com/games/office-management-101
 */
package com.pcw.game.Scripting;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.utils.JsonReader;
import com.badlogic.gdx.utils.JsonValue;
import com.badlogic.gdx.utils.ObjectMap;
import org.luaj.vm2.Varargs;

/*
 * Manages the Lua script cache and provides methods to call Lua script functions
 */
public final class ScriptManager {
    private static ObjectMap<String, LuaScript> scripts;
    private static JsonValue json;

    // Constructor
    public ScriptManager() {
        ScriptManager.scripts = new ObjectMap<String, LuaScript>();
        ScriptManager.json = new JsonReader().parse(Gdx.files.external("PCW/gamemodes/scripts.json"));
    }

    // Load file by script key, returns false if fails
    // You don't need to call this yourself, since the function calling methods do it already
    public static boolean load(String key) {
        if (ScriptManager.json.has(key)) {
            if (ScriptManager.json.get(key).isString()) {
                // Get the script filename from the json file and load the script
                // THIS WILL BE LOADED EXTERNALLY DUE TO A MODIFICATION TO THE LuaScript CLASS.
                boolean success = ScriptManager.add(key, "PCW/gamemodes/" + ScriptManager.json.getString(key));
                if (!success) {
                    Gdx.app.log("Debug", "Loading of " + key + " script failed!");
                } else {
                    Gdx.app.log("Debug", "Loading of " + key + " script successful!");
                }
                return success;
            }
        }

        Gdx.app.log("Debug", "Loading of " + key + " script failed! Script not registered.");
        return false;
    }

    // Add the script to cache, returns false when fails
    // You don't need to call this yourself, since the function calling methods do it already
    public static boolean add(String key, String fileName) {
        LuaScript script = new LuaScript(fileName);
        if (script.canExecute()) {
            // If already exists in cache, then delete the old one first
            if (ScriptManager.scripts.containsKey(key)) {
                ScriptManager.scripts.remove(key);
            }
            // Add to the cache
            ScriptManager.scripts.put(key, script);
            // Register ExecuteScript function, so it can be called from Lua scripts
            script.registerJavaFunction(ExecuteScript.getInstance());

            return true;
        } else {
            Gdx.app.log("Debug", key + " script " + fileName + " not found!");
        }

        return false;
    }

    // Reload the script, but only if it already exists in the cache
    public static boolean reload(String key) {
        if (ScriptManager.scripts.containsKey(key)) {
            return add(key, ScriptManager.scripts.get(key).scriptFileName);
        }

        return false;
    }

    // Execute a Lua function functionName in script file (key) and pass the rest of the parameters to the function
    // Returns false when fails
    public static boolean executeFunction(String key, String functionName, Object... objects) {
        // Run the function if the script file is the cache
        if (ScriptManager.scripts.containsKey(key)) {
            return ScriptManager.scripts.get(key).executeFunction(functionName, objects);
        } else {
            // Try to load the script to the cache
            if (!ScriptManager.load(key)) {
                return false;
            }
            // Run the function
            return ScriptManager.scripts.get(key).executeFunction(functionName, objects);
        }
    }

    // Execute a Lua function functionName in script file (key) and pass the array of parameters to the function
    // Returns false when fails
    public static boolean executeFunctionParamsAsArray(String key, String functionName, Object[] objects) {
        // Run the function if the script file is the cache
        if (ScriptManager.scripts.containsKey(key)) {
            return ScriptManager.scripts.get(key).executeFunctionParamsAsArray(functionName, objects);
        } else {
            // Try to load the script to the cache
            if (!ScriptManager.load(key)) {
                return false;
            }
            // Run the function
            return ScriptManager.scripts.get(key).executeFunctionParamsAsArray(functionName, objects);
        }
    }

    // Execute a Lua function "init" in script file (key) and pass the array of parameters to the function
    // Returns false when fails
    public static boolean executeInit(String key, Object... objects) {
        // Run the function if the script file is the cache
        if (ScriptManager.scripts.containsKey(key)) {
            return ScriptManager.scripts.get(key).executeInit(objects);
        } else {
            // Try to load the script to the cache
            if (!ScriptManager.load(key)) {
                return false;
            }
            // Run the function
            return ScriptManager.scripts.get(key).executeInit(objects);
        }
    }

    // Execute a Lua function "update" in script file (key) and pass the array of parameters to the function
    // Returns false when fails
    public static boolean executeUpdate(String key, Object... objects) {
        return ScriptManager.executeFunction(key, "update", objects);
    }

    // Clear the whole script cache
    public static void dispose() {
        ScriptManager.scripts = new ObjectMap<String, LuaScript>();
    }

    public static Varargs getLastResults(String key){
        return ScriptManager.scripts.get(key).lastResults;
    }
}
