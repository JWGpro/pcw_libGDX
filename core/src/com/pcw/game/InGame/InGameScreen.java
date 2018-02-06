package com.pcw.game.InGame;

import com.badlogic.gdx.*;
import com.badlogic.gdx.assets.loaders.resolvers.ExternalFileHandleResolver;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.input.GestureDetector;
import com.badlogic.gdx.input.GestureDetector.GestureListener;
import com.badlogic.gdx.maps.tiled.*;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.scenes.scene2d.*;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.ScreenViewport;
import com.pcw.game.PCW;
import com.pcw.game.Scripting.ScriptManager;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class InGameScreen implements Screen, InputProcessor, GestureListener {

    private Stage gameStage;
    private Stage UIStage;
    private Group menuActors = new Group();
    private boolean menuRaised = false;
    private InputMultiplexer im;
    private Game game;
    private OrthographicCamera gameCamera;
    private OrthographicCamera UICamera;
    private TiledMap tiledMap;
    private TiledMapRenderer tiledMapRenderer;
    private ScriptManager scriptmanager;
    Runtime runtime = Runtime.getRuntime();

    public InGameScreen(Game thegame) {
        game = thegame;

        // Camera setup.
        float w = Gdx.graphics.getWidth();
        float h = Gdx.graphics.getHeight();
        gameCamera = new OrthographicCamera();
        UICamera = new OrthographicCamera();

        // Game stage and UI stage (independent updating).
        gameStage = new Stage(new ScreenViewport(gameCamera));
        UIStage = new Stage(new FitViewport(w, h, UICamera));
//        UICamera.zoom = UICamera.zoom * 2;
//        UICamera.position.set(w/4,-h/2,0f);
//        UICamera.position.set(0f,0f,0f);

        // Tiled map stuff.
        tiledMap = new TmxMapLoader(new ExternalFileHandleResolver()).load("PCW/maps/testmap.tmx");
        tiledMapRenderer = new OrthogonalTiledMapRenderer(tiledMap);

        // Initialise game mode script.
        scriptmanager = new ScriptManager();
        scriptmanager.executeInit("Classic", this, gameCamera, gameStage, UICamera, UIStage, tiledMap, Gdx.files.getExternalStoragePath());

        // Set input processor to allow the argument to receive input events.
        // If you pass "stage", any stage.addListener stuff works, and Actor actions work.
        // If you pass "this", any InputProcessor methods work, which means Lua script can take control.

        // An InputMultiplexer will pass input events to the first argument first and the last argument last.
        // The idea is that stuff on top (like UI) should receive it first.

        GestureDetector gd = new GestureDetector(this);
        im = new InputMultiplexer(UIStage, gameStage, this, gd);
        Gdx.input.setInputProcessor(im);
    }

    public TiledMapTileLayer.Cell newCell() {
        return new TiledMapTileLayer.Cell();
    }

    public MapActor addLuaActor(String spritedir, Float alphaval, Float bound){
        MapActor luaActor = new MapActor(spritedir, alphaval, bound);
        gameStage.addActor(luaActor);
        return luaActor;
    }

    public void catchCursor(boolean bool){
        // Locks and hides the cursor.
        Gdx.input.setCursorCatched(bool);
    }

    public Object reflect(String classname, Object[] luaparams, Object[] args){
        Class theclass;

        try {
            theclass = Class.forName(classname);
        } catch (ClassNotFoundException e) {
            System.out.println("Java reflection: Class not found! (" + e.toString() + ")");
            return false;
        }

        String simplename = theclass.getSimpleName();

        // Rebuild the list of parameters from Lua and sort them.
        String[] lparams = Arrays.copyOf(luaparams, luaparams.length, String[].class);
        Arrays.sort(lparams);

        // There may be multiple constructors - Lua needs to specify the one which takes the args it passes.
        Constructor[] constructors = theclass.getConstructors();
        Constructor constructor = null;

        for (Constructor con : constructors) {
            // Check each constructor; continue if the number of params mismatches.
            Class[] cparams = con.getParameterTypes();
            // Convert the Class[] to a String[] composed of simple names.
            String[] sparams = new String [cparams.length];
            for (int i = 0; i < cparams.length; i++) {
                sparams[i] = cparams[i].getSimpleName();
            }
            Arrays.sort(sparams);
            // Success if the sorted arrays are equal.
            if (Arrays.equals(sparams, lparams)) {
                constructor = con;
                break;
            }
        }

        // If there is no constructor then return...this whole approach seems like shit but let's see if it works.
        if (constructor == null) {
            System.out.println("Java reflection: Could not find a " + simplename + " constructor with those "
                    + "parameters!");
            return false;
        }

        try {
            // Instantiate.
            // The arguments passed from Lua MUST still be ordered as the constructor requires them.
            Object newobject = constructor.newInstance(args);
            System.out.println("Java reflection: " + simplename + " instantiated using parameters: "
                    + Arrays.toString(luaparams));
            return newobject;
        } catch (Exception e) {
            System.out.println("Java reflection: Could not instantiate from " + simplename + " constructor! ("
                    + e.toString() + ")\n Check that you're calling the right constructor and passing the right "
                    + "objects!\n Parameters: " + Arrays.toString(luaparams));
            return false;
        }
    }

    public ChangeListener addChangeListener(Actor luawidget, Object luafunc, Object luaobject) {
        final Object func = luafunc;
        final Object obj = luaobject;
        ChangeListener lis;
        luawidget.addListener(lis = new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                ScriptManager.executeFunction("Classic", "runlistener", func, obj, event, actor);
            }
        });
        return lis;
    }

    public void toggleMenu(){
        if (!menuRaised) {
            UIStage.addActor(menuActors);
            menuRaised = true;
        } else {
            menuActors.remove();
            menuRaised = false;
        }
    }

    @Override
    public void show() {

    }

    @Override
    public void render(float delta) {
//        Gdx.gl.glClearColor(0, 0, 0, 1);
//        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // Run game mode script regular loop.
        scriptmanager.executeFunction("Classic", "loop", delta);
        gameCamera.update();
        tiledMapRenderer.setView(gameCamera);
        tiledMapRenderer.render();

        gameStage.act(delta);
        UIStage.act(delta);

        gameStage.draw();
        UIStage.draw();

//        System.out.println((runtime.totalMemory() - runtime.freeMemory()) / 1048576);
    }

    @Override
    public void resize(int width, int height) {
        gameStage.getViewport().update(width, height, false);
        UIStage.getViewport().update(width, height, false);

    }

    @Override
    public void pause() {

    }

    @Override
    public void resume() {

    }

    @Override
    public void hide() {

    }

    @Override
    public void dispose() {
        // make sure you dispose() or something when you quit out...see Menu class.
        gameStage.dispose();
        UIStage.dispose();
        tiledMap.dispose();
        scriptmanager.dispose();
        // Does the stage get rid of all the actors inside it?
    }

    // Input event handling methods below.
    // Defers the return values to the script. Or it should, but it actually just always returns true.
    // So, like the stages before it, it's just eating the input.

    @Override
    public boolean keyDown(int keycode) {
        return scriptmanager.executeFunction("Classic", "keyDown", keycode);
    }

    @Override
    public boolean keyUp(int keycode) {
        return scriptmanager.executeFunction("Classic", "keyUp", keycode);
    }

    @Override
    public boolean keyTyped(char character) {
        return scriptmanager.executeFunction("Classic", "keyTyped", character);
    }

    @Override
    public boolean touchDown(int screenX, int screenY, int pointer, int button) {
        return scriptmanager.executeFunction("Classic", "touchDown", screenX, screenY, pointer, button);
    }

    @Override
    public boolean touchUp(int screenX, int screenY, int pointer, int button) {
        return scriptmanager.executeFunction("Classic", "touchUp", screenX, screenY, pointer, button);
    }

    @Override
    public boolean touchDragged(int screenX, int screenY, int pointer) {
        return scriptmanager.executeFunction("Classic", "touchDragged", screenX, screenY, pointer);
    }

    @Override
    public boolean mouseMoved(int screenX, int screenY) {
        return scriptmanager.executeFunction("Classic", "mouseMoved", screenX, screenY);
    }

    @Override
    public boolean scrolled(int amount) {
        return scriptmanager.executeFunction("Classic", "scrolled", amount);
    }

    // Touch gesture detector events below.

    @Override
    public boolean touchDown(float x, float y, int pointer, int button) {
        System.out.println("Java: this was a different touchDown event that took floats");
        return true;
    }

    @Override
    public boolean tap(float x, float y, int count, int button) {
        return scriptmanager.executeFunction("Classic", "tap", x, y, count, button);
    }

    @Override
    public boolean longPress(float x, float y) {
        return scriptmanager.executeFunction("Classic", "longPress", x, y);
    }

    @Override
    public boolean fling(float velocityX, float velocityY, int button) {
        return scriptmanager.executeFunction("Classic", "fling", velocityX, velocityY, button);
    }

    @Override
    public boolean pan(float x, float y, float deltaX, float deltaY) {
        return scriptmanager.executeFunction("Classic", "pan", x, y, deltaX, deltaY);
    }

    @Override
    public boolean panStop(float x, float y, int pointer, int button) {
        return scriptmanager.executeFunction("Classic", "panStop", x, y, pointer, button);
    }

    @Override
    public boolean zoom(float initialDistance, float distance) {
        return scriptmanager.executeFunction("Classic", "zoom", initialDistance, distance);
    }

    @Override
    public boolean pinch(Vector2 initialPointer1, Vector2 initialPointer2, Vector2 pointer1, Vector2 pointer2) {
        return scriptmanager.executeFunction("Classic", "pinch", initialPointer1, initialPointer2, pointer1, pointer2);
    }

    @Override
    public void pinchStop() {
        scriptmanager.executeFunction("Classic", "pinchStop");
    }
}