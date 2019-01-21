package com.pcw.game.InGame;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.*;
import com.badlogic.gdx.scenes.scene2d.*;
import com.badlogic.gdx.scenes.scene2d.actions.*;
import com.pcw.game.Scripting.ScriptManager;
import javafx.scene.Parent;
import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.jse.JsePlatform;

public class MapActor extends Actor {

    private float alpha = 1.0f;
    private static final Color DEFAULT_COLOUR = new Color(0xffffffff);
    private Stage parentStage;
    // Possibly other stuff like tints (for teams), rotation, mirrored etc.

    private boolean isAnimated = false;
    private Animation<TextureRegion> anim;
    private TextureAtlas atlas;
    private TextureRegion region;
    private String animname;
    private float frametime;
    private Animation.PlayMode playmode;
    private float stateTime;

    // This actor can switch between animated and not, once constructed.

    // The Animation class does not seem to be capable of variable frame times out-of-box. I could implement it later.

    public MapActor(Stage stg) {
        parentStage = stg;
    }

    public void setImage(Texture newtex) {
        isAnimated = false;
        region = new TextureRegion(newtex);
    }

    public void animate(TextureAtlas ta, String an, float ft, Animation.PlayMode pm) {
        // Could be considered the constructor for an animated actor.
        atlas = ta;
        animname = an;
        frametime = ft;
        playmode = pm;

        setAnim(animname);
    }

    public String getAnimName(){
        return animname;
    }

    public void setAnim (String newanim) {
        isAnimated = true;
        animname = newanim;
        anim = new Animation<TextureRegion>(frametime, atlas.findRegions(animname), playmode);
        stateTime = 0f;
    }

    public boolean isPlayingAnim() {
        return !anim.isAnimationFinished(stateTime);
    }

    public Animation.PlayMode getPlayMode(){
        return anim.getPlayMode();
    }

    public void setPlayMode(Animation.PlayMode pm) {
        playmode = pm;
        anim.setPlayMode(playmode);
    }

    public float getFrameTime() {
        return frametime;
    }

    public void setFrameTime (float ft) {
        frametime = ft;
        anim.setFrameDuration(frametime);
    }

    public boolean isActing() {
        return (getActions().size > 0);
    }

    public void tint(int rgba8888) {
        // why have i done this instead of this.setColor()?
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
        // And yeah I know I could use a SequenceAction for pathing.
        this.addAction(Actions.moveTo(x, y, duration));
    }

    public void hide() {
        // How is this any different to killing the unit?
        // The MapActor will GC if there are no references to it.
        // Not sure how that works if the only reference is in Lua. lol.
        // Maybe a collectgarbage() or something. Dunno.
        this.remove();
    }

    public void unhide() {
        // Ends up on top of everything where it wasn't before, but that shouldn't be a problem.
        parentStage.addActor(this);
    }

    public float getAlpha() {
        return alpha;
    }

    public void setAlpha(float alphaval) {
        alpha = alphaval;
    }

    @Override
    public void draw(Batch batch, float parentAlpha) {
        Color color = getColor();
        batch.setColor(color.r, color.g, color.b, (color.a * parentAlpha * alpha));

        if (isAnimated) {
            region = anim.getKeyFrame(stateTime);
        }
        batch.draw(region, this.getX(), this.getY());
    }

    @Override
    public void act(float delta) {
        super.act(delta);
        // For global anim sync, could get stateTime upon construction,
        //  or ask a parent for it every frame, so that you don't keep storing the same time.
        // Though a method call is probably slower than storing and computing it.
        // Need a benchmarking map at some point.
        stateTime += delta;
    }

    @Override
    protected void positionChanged() {
        super.positionChanged();
    }
}