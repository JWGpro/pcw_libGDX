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

public class PlayMenu extends Menu {

    public PlayMenu(Game thegame) {
        // Calls the constructor in Menu.
        super(thegame);

        // Label.
        Label title = new Label("Playing Screen", PCW.gameSkin,"big-black");
        title.setAlignment(Align.center);
        title.setY(Gdx.graphics.getHeight()*2/3);
        title.setWidth(Gdx.graphics.getWidth());
        stage.addActor(title);

        // Start button.
        TextButton startButton = new TextButton("Start",PCW.gameSkin);
        startButton.setWidth(Gdx.graphics.getWidth()/2);
        startButton.setPosition(Gdx.graphics.getWidth()/2-startButton.getWidth()/2,Gdx.graphics.getHeight()/4-startButton.getHeight()/2);
        startButton.addListener(new InputListener(){
            @Override
            public void touchUp (InputEvent event, float x, float y, int pointer, int button) {
                dispose();
                game.setScreen(new InGameScreen(game, "Classic", "Play"));
            }
            @Override
            public boolean touchDown (InputEvent event, float x, float y, int pointer, int button) {
                return true;
            }
        });
        stage.addActor(startButton);
    }

}
