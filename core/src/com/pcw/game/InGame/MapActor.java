package com.pcw.game.InGame;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.InputListener;
import com.badlogic.gdx.scenes.scene2d.Touchable;
import com.badlogic.gdx.scenes.scene2d.actions.MoveByAction;

public class MapActor extends Actor {

    private Sprite sprite;
    private Float alpha;
    // Possibly other stuff like tints (for teams), rotation, mirrored etc.

    public MapActor(String spritedir, Float alphaval, Float bound) {
        sprite = new Sprite(new Texture(Gdx.files.external(spritedir)));
        alpha = alphaval;

        // The bounds could either be the size of the sprite (could overlap/exceed cell), or the cell size of the map.
        setBounds(this.getX(), this.getY(), bound, bound);
        setTouchable(Touchable.enabled);

        addListener(new InputListener(){
            @Override
            public boolean keyDown(InputEvent event, int keycode) {
                if(keycode == Input.Keys.RIGHT){
                    MoveByAction mba = new MoveByAction();
                    mba.setAmount(100f,0f);
                    mba.setDuration(5f);

                    MapActor.this.addAction(mba);
                }
                return true;
            }
        });
    }

    public String getSprite() {
        // Returns some memory address instead of the filename at the moment.
        // Could store the filename passed in from the constructor, or there may be a way of actually retrieving it.
        return sprite.getTexture().toString();
    }

    public void setSprite(String spritedir) {
        sprite.getTexture().dispose();
        sprite.setTexture(new Texture(Gdx.files.external(spritedir)));
    }

    public Float getAlpha() {
        return alpha;
    }

    public void setAlpha(Float alphaval) {
        alpha = alphaval;
    }

    @Override
    public void draw(Batch batch, float parentAlpha) {
        sprite.draw(batch, alpha);
    }

    @Override
    public void act(float delta) {
        super.act(delta);
    }

    @Override
    protected void positionChanged() {
        sprite.setPosition(this.getX(), this.getY());
        super.positionChanged();
    }
}