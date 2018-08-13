package com.pcw.game.InGame;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.scenes.scene2d.*;
import com.badlogic.gdx.scenes.scene2d.actions.Actions;
import com.badlogic.gdx.scenes.scene2d.actions.ColorAction;
import com.badlogic.gdx.scenes.scene2d.actions.MoveByAction;
import com.badlogic.gdx.scenes.scene2d.actions.MoveToAction;
import com.pcw.game.Scripting.ScriptManager;
import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.jse.JsePlatform;

public class MapActor extends Actor {

    private Sprite sprite;
    private Float alpha;
    private static final Color DEFAULT_COLOUR = new Color(0xffffffff);
    private Stage parentStage;
    // Possibly other stuff like tints (for teams), rotation, mirrored etc.

    public MapActor(String spritedir, Float alphaval) {
        sprite = new Sprite(new Texture(Gdx.files.external(spritedir)));
        alpha = alphaval;

        // Bounds don't do anything right now, so they're disabled.
        // Lua actors should be referred to by Lua objects, not MapActors.
        // Could probably do it by reflecting Touchable.enabled if you really wanted to anyway.
//        // The bounds could either be the size of the sprite (could overlap/exceed cell), or the cell size of the map.
//        setBounds(this.getX(), this.getY(), bound, bound);
//        setTouchable(Touchable.enabled);
    }

    public void tint(int rgba8888) {
        ColorAction ca = new ColorAction();
        ca.setEndColor(new Color(rgba8888));
        this.addAction(ca);
    }

    public void resetTint() {
        ColorAction ca = new ColorAction();
        ca.setEndColor(DEFAULT_COLOUR);
        this.addAction(ca);
    }

    // getColour method

    public void moveTo(float x, float y, float duration) {
        // Apparently this action is pooled.
        this.addAction(Actions.moveTo(x, y, duration));
    }

    public void hide() {
        // How is this any different to killing the unit?
        // The MapActor will GC if there are no references to it.
        // Not sure how that works if the only reference is in Lua. lol.
        // Maybe a collectgarbage() or something. Dunno.
        parentStage = this.getStage();
        this.remove();
    }

    public void show() {
        // Ends up on top of everything where it wasn't before, but that shouldn't be a problem.
        parentStage.addActor(this);
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
        Color color = getColor();
        batch.setColor(color.r, color.g, color.b, (color.a * parentAlpha * alpha));
        batch.draw(sprite, this.getX(), this.getY());
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