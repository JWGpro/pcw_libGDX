package com.pcw.game.InGame;

import com.badlogic.gdx.*;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TiledMapRenderer;
import com.badlogic.gdx.maps.tiled.TmxMapLoader;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener;
import com.badlogic.gdx.utils.viewport.ScreenViewport;
import com.pcw.game.Menus.MainMenu;
import com.pcw.game.Scripting.ScriptManager;

import java.util.Arrays;

public class InGameScreen implements Screen, InputProcessor {

    private Stage stage;
    private Game game;
    private OrthographicCamera camera;
    private TiledMap tiledMap;
    private TiledMapRenderer tiledMapRenderer;
    private ScriptManager scriptmanager;

    public InGameScreen(Game thegame) {
        game = thegame;

        // Camera setup.
//        float w = Gdx.graphics.getWidth();
//        float h = Gdx.graphics.getHeight();
        camera = new OrthographicCamera();
//        camera.setToOrtho(false, w, h);
//        camera.update();

        // Stage, viewport.
        // Would actually have two different stages, for the regular game and the overlain menus I guess.
        stage = new Stage(new ScreenViewport(camera));

        // Tiled map stuff.
        tiledMap = new TmxMapLoader().load("testmap.tmx");
        tiledMapRenderer = new OrthogonalTiledMapRenderer(tiledMap);

//        // Placeholder listener. Only here to show how this sort of thing works.
//        stage.addListener(new ClickListener(Input.Buttons.RIGHT) {
//            @Override
//            public void clicked(InputEvent event, float x, float y) {
//                System.out.println("wats up men");
//                game.setScreen(new MainMenu(game));
//            }
//        });

        // Initialise game mode script.
        scriptmanager = new ScriptManager();
        scriptmanager.executeInit("Classic", this, camera, stage, tiledMap);

        // Set input processor to allow the argument to receive input events.
        // If you pass "stage", any stage.addListener stuff works.
        // If you pass "this", any InputProcessor methods work.
        // This is where multiplexing comes in. Just use a multiplexer to get from both.
        // For now we'll just see what we need.

        // We implement the InputProcessor methods and then call individual Lua functions to deal with the input.
        Gdx.input.setInputProcessor(stage);

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
        camera.update();
        tiledMapRenderer.setView(camera);
        tiledMapRenderer.render();

        stage.act(delta);
        stage.draw();
    }

    @Override
    public void resize(int width, int height) {
        // use true here to center the camera
        // that's what you probably want in case of a UI
        stage.getViewport().update(width, height, false);

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
        stage.dispose();
        tiledMap.dispose();
        scriptmanager.dispose();

        // Does the stage get rid of all the actors inside it?
    }

    // Input event handling methods below.

    @Override
    public boolean keyDown(int keycode) {
        return false;
    }

    @Override
    public boolean keyUp(int keycode) {
        return false;
    }

    @Override
    public boolean keyTyped(char character) {
        return false;
    }

    @Override
    public boolean touchDown(int screenX, int screenY, int pointer, int button) {
        return false;
    }

    @Override
    public boolean touchUp(int screenX, int screenY, int pointer, int button) {
        return false;
    }

    @Override
    public boolean touchDragged(int screenX, int screenY, int pointer) {
        return false;
    }

    @Override
    public boolean mouseMoved(int screenX, int screenY) {
        scriptmanager.executeFunction("Classic", "mouseMoved", screenX, screenY);
        return false;
    }

    @Override
    public boolean scrolled(int amount) {
        return false;
    }
}