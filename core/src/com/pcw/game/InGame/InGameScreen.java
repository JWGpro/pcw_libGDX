package com.pcw.game.InGame;

import com.badlogic.gdx.*;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.assets.loaders.resolvers.ExternalFileHandleResolver;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.*;
import com.badlogic.gdx.graphics.g2d.*;
import com.badlogic.gdx.input.GestureDetector;
import com.badlogic.gdx.input.GestureDetector.GestureListener;
import com.badlogic.gdx.maps.MapLayers;
import com.badlogic.gdx.maps.tiled.*;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;
import com.badlogic.gdx.maps.tiled.tiles.AnimatedTiledMapTile;
import com.badlogic.gdx.maps.tiled.tiles.StaticTiledMapTile;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.scenes.scene2d.*;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.ScreenViewport;
import com.pcw.game.PCW;
import com.pcw.game.Scripting.ScriptManager;

import java.io.BufferedReader;
import java.io.IOException;
import java.lang.reflect.Constructor;
import java.util.Arrays;

public class InGameScreen implements Screen, InputProcessor, GestureListener {

    private Stage gameStage;
    private Stage UIStage;
    private Group menuActors = new Group();
    private boolean menuRaised = false;
    private String parentMode;
    private String childMode;
    private AssetManager assetManager;
    private InputMultiplexer im;
    private Game game;
    private OrthographicCamera gameCamera;
    private OrthographicCamera UICamera;
    private TiledMap tiledMap;
    private TiledMapRenderer tiledMapRenderer;
    private ScriptManager scriptmanager;
    Runtime runtime = Runtime.getRuntime();

    public InGameScreen(Game thegame, String parentmode, String childmode) {
        game = thegame;
        parentMode = parentmode;
        childMode = childmode;

        // Loading assets...
        assetManager = new AssetManager(new ExternalFileHandleResolver());
        // Since the script can use whatever assets it wants, it must declare and load them itself.

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
//        tiledMap = new TmxMapLoader(new ExternalFileHandleResolver()).load("PCW/maps/testmap.tmx");
        tiledMap = new TiledMap();
        tiledMapRenderer = new OrthogonalTiledMapRenderer(tiledMap);

        // Initialise game mode script.
        scriptmanager = new ScriptManager();
        scriptmanager.executeInit(parentMode,
                childMode,
                this,
                gameCamera,
                gameStage,
                UICamera,
                UIStage,
                tiledMap,
                Gdx.files.getExternalStoragePath()
        );

        // Set input processor to allow the argument to receive input events.
        // If you pass "stage", any stage.addListener stuff works, and Actor actions work.
        // If you pass "this", any InputProcessor methods work, which means Lua script can take control.

        // An InputMultiplexer will pass input events to the first argument first and the last argument last.
        // The idea is that stuff on top (like UI) should receive it first.

        GestureDetector gd = new GestureDetector(this);
        im = new InputMultiplexer(UIStage, gameStage, this, gd);
        Gdx.input.setInputProcessor(im);
    }

    public TiledMapTileLayer newMapLayer(String name, int w, int h, int cellsize) {
        MapLayers layers = tiledMap.getLayers();
        TiledMapTileLayer tileLayer = new TiledMapTileLayer(w, h, cellsize, cellsize);
        tileLayer.setName(name);
        layers.add(tileLayer);
        for (int x = 0; x < w; x++) {
            for (int y = 0; y < h; y++) {
                // Fills the layer with cells - tiles should then be assigned to the cells in script.
                TiledMapTileLayer.Cell cell = new TiledMapTileLayer.Cell();
                tileLayer.setCell(x, y, cell);
            }
        }
        return tileLayer;
    }

    public TiledMapTileSet newTileSet(String name) {
        TiledMapTileSets sets = tiledMap.getTileSets();
        TiledMapTileSet tileSet = new TiledMapTileSet();
        tileSet.setName(name);
        sets.addTileSet(tileSet);
        return tileSet;
    }

    public StaticTiledMapTile newStaticTile(String path) {
        FileHandle fh = new ExternalFileHandleResolver().resolve("PCW/" + path);
        return new StaticTiledMapTile(new TextureRegion(new Texture(fh)));
    }

    public AnimatedTiledMapTile newAnimatedTile(float interval, String path) {
        // should actually be an interval array.

        FileHandle fh = new ExternalFileHandleResolver().resolve("PCW/" + path);
        Array<StaticTiledMapTile> tiles = new Array<StaticTiledMapTile>();
        //for each region in the TextureAtlas
//        tiles.add(new StaticTiledMapTile(new TextureAtlas.AtlasRegion(fh, 0,0,0,0)));
        //etc
        return new AnimatedTiledMapTile(interval, tiles);
    }

    public TiledMapTileLayer.Cell newCell() {
        return new TiledMapTileLayer.Cell();
    }

    public MapActor newActor(boolean drawNow){
        MapActor luaActor = new MapActor(gameStage);
        if (drawNow) {
            luaActor.unhide();
        }
        return luaActor;
    }

    public Object getAnimationPlayModes() {
        // unsure of a more elegant way of doing this.
        return Animation.PlayMode.class;
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
            System.out.println("Java reflection: ERROR! Class not found! (" + e.toString() + ")");
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
            System.out.println("Java reflection: ERROR! Could not find a " + simplename + " constructor with those "
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
            System.out.println("Java reflection: ERROR! Could not instantiate from " + simplename + " constructor! ("
                    + e.toString() + ")\n  Check that you're calling the right constructor and passing the right "
                    + "objects!\n  Parameters: " + Arrays.toString(luaparams));
            return false;
        }
    }

    public ChangeListener addChangeListener(Actor luawidget, Object luafunc, Object luaobj, Object luaargs) {
        // You can pass an object in from Lua if you want to use a method on it; button, self.method, self, args.
        final Object func = luafunc;
        final Object obj = luaobj;
        final Object args = luaargs;
        ChangeListener lis;
        luawidget.addListener(lis = new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                ScriptManager.executeFunction(parentMode, "runlistener", func, obj, args, event, actor);
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

    public void queueLoadAsset(String path, String classname) {
        // can use params too, e.g. for texture filtering...
        // i don't expect it to end up looking like this in final. though i also don't expect to use reflection.

        if (classname.equals("Texture")) {
            assetManager.load(path, Texture.class);
        } else if (classname.equals("Skin")) {
            assetManager.load(path, Skin.class);
        } else if (classname.equals("TextureAtlas")) {
            assetManager.load(path, TextureAtlas.class);
        } else if (classname.equals("Music")) {
            assetManager.load(path, Music.class);
        } else if (classname.equals("Sound")) {
            assetManager.load(path, Sound.class);
        } else if (classname.equals("ParticleEffect")) {
            assetManager.load(path, ParticleEffect.class);
        } else if (classname.equals("Pixmap")) {
            assetManager.load(path, Pixmap.class);
        } else if (classname.equals("BitmapFont")) {
            assetManager.load(path, BitmapFont.class);
        } else {
            System.out.println("ERROR: didn't recognise the class name '" + classname + "' for file " + path);
        }

        System.out.println("Queued " + classname + ": " + path);
    }

    public void finishLoadingAssets() {
        assetManager.finishLoading();
    }

    public Object getAsset(String path){
        // This is the preferred way for script to manipulate and play Sound assets, since it gives full control.
        return assetManager.get(path);
    }

    public void throwException() {
        // TODO: When you want a script crash to stop the presses. Could just quit this screen with an error message.
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
        scriptmanager.executeFunction(parentMode, "loop", delta);
        gameCamera.update();
        tiledMapRenderer.setView(gameCamera);
        tiledMapRenderer.render();

        gameStage.act(delta);
        UIStage.act(delta);

        gameStage.draw();
        UIStage.draw();

//        System.out.println((runtime.totalMemory() - runtime.freeMemory()) / 1048576);
//        System.out.println(1/delta);  // Makeshift framerate display
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
        assetManager.dispose();
        tiledMap.dispose();
        scriptmanager.dispose();
        // Does the stage get rid of all the actors inside it?
    }

    // Input event handling methods below.
    // Defers the return values to the script. Or it should, but it actually just always returns true.
    // So, like the stages before it, it's just eating the input.

    @Override
    public boolean keyDown(int keycode) {
        return scriptmanager.executeFunction(parentMode, "keyDown", keycode);
    }

    @Override
    public boolean keyUp(int keycode) {
        return scriptmanager.executeFunction(parentMode, "keyUp", keycode);
    }

    @Override
    public boolean keyTyped(char character) {
        return scriptmanager.executeFunction(parentMode, "keyTyped", character);
    }

    @Override
    public boolean touchDown(int screenX, int screenY, int pointer, int button) {
        return scriptmanager.executeFunction(parentMode, "touchDown", screenX, screenY, pointer, button);
    }

    @Override
    public boolean touchUp(int screenX, int screenY, int pointer, int button) {
        return scriptmanager.executeFunction(parentMode, "touchUp", screenX, screenY, pointer, button);
    }

    @Override
    public boolean touchDragged(int screenX, int screenY, int pointer) {
        return scriptmanager.executeFunction(parentMode, "touchDragged", screenX, screenY, pointer);
    }

    @Override
    public boolean mouseMoved(int screenX, int screenY) {
        return scriptmanager.executeFunction(parentMode, "mouseMoved", screenX, screenY);
    }

    @Override
    public boolean scrolled(int amount) {
        return scriptmanager.executeFunction(parentMode, "scrolled", amount);
    }

    // Touch gesture detector events below.

    @Override
    public boolean touchDown(float x, float y, int pointer, int button) {
        System.out.println("Java: this was a different touchDown event that took floats");
        return true;
    }

    @Override
    public boolean tap(float x, float y, int count, int button) {
        return scriptmanager.executeFunction(parentMode, "tap", x, y, count, button);
    }

    @Override
    public boolean longPress(float x, float y) {
        return scriptmanager.executeFunction(parentMode, "longPress", x, y);
    }

    @Override
    public boolean fling(float velocityX, float velocityY, int button) {
        return scriptmanager.executeFunction(parentMode, "fling", velocityX, velocityY, button);
    }

    @Override
    public boolean pan(float x, float y, float deltaX, float deltaY) {
        return scriptmanager.executeFunction(parentMode, "pan", x, y, deltaX, deltaY);
    }

    @Override
    public boolean panStop(float x, float y, int pointer, int button) {
        return scriptmanager.executeFunction(parentMode, "panStop", x, y, pointer, button);
    }

    @Override
    public boolean zoom(float initialDistance, float distance) {
        return scriptmanager.executeFunction(parentMode, "zoom", initialDistance, distance);
    }

    @Override
    public boolean pinch(Vector2 initialPointer1, Vector2 initialPointer2, Vector2 pointer1, Vector2 pointer2) {
        return scriptmanager.executeFunction(parentMode, "pinch", initialPointer1, initialPointer2, pointer1, pointer2);
    }

    @Override
    public void pinchStop() {
        scriptmanager.executeFunction(parentMode, "pinchStop");
    }
}