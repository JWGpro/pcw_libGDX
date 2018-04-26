package com.pcw.game.Menus;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.InputListener;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.utils.Align;
import com.pcw.game.InGame.InGameScreen;
import com.pcw.game.PCW;

public class MainMenu extends Menu {

    public MainMenu(Game thegame) {
        // Calls the constructor in Menu.
        super(thegame);

        // Title label.
        Label title = new Label("PCW", PCW.gameSkin,"big-black");
        title.setAlignment(Align.center);
        title.setY(Gdx.graphics.getHeight()*2/3);
        title.setWidth(Gdx.graphics.getWidth());
        stage.addActor(title);

        // Play menu button.
        TextButton playButton = new TextButton("Play",PCW.gameSkin);
        playButton.setWidth(Gdx.graphics.getWidth()/2);
        playButton.setPosition(Gdx.graphics.getWidth()/2-playButton.getWidth()/2,Gdx.graphics.getHeight()/2-playButton.getHeight()/2);
        playButton.addListener(new InputListener(){
            @Override
            public void touchUp (InputEvent event, float x, float y, int pointer, int button) {
                dispose();
                game.setScreen(new PlayMenu(game));
            }
            @Override
            public boolean touchDown (InputEvent event, float x, float y, int pointer, int button) {
                return true;
            }
        });
        stage.addActor(playButton);

        // Map Editor button.
        TextButton editorButton = new TextButton("Map Editor",PCW.gameSkin);
        editorButton.setWidth(Gdx.graphics.getWidth()/2);
        editorButton.setPosition(Gdx.graphics.getWidth()/2-editorButton.getWidth()/2,Gdx.graphics.getHeight()/4-editorButton.getHeight()/2);
        editorButton.addListener(new InputListener(){
            @Override
            public void touchUp (InputEvent event, float x, float y, int pointer, int button) {
                dispose();
                game.setScreen(new InGameScreen(game, "Classic", "MapEditor"));
            }
            @Override
            public boolean touchDown (InputEvent event, float x, float y, int pointer, int button) {
                return true;
            }
        });
        stage.addActor(editorButton);

    }

}