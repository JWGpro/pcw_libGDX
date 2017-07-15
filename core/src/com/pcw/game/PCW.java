package com.pcw.game;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.utils.GdxRuntimeException;
import com.pcw.game.Menus.MainMenu;

import java.io.*;
import java.nio.Buffer;
import java.nio.channels.FileChannel;
import java.util.Scanner;

public class PCW extends Game {

    static public Skin gameSkin;

    public void create() {
        // Read the asset manifest and check each line in it.
        try {
            checkManifest();
        } catch (IOException e) {
            System.out.println("IO exception while checking asset manifest:\n " + e.toString());
        }

        // Set skin and set screen to the main menu.
        gameSkin = new Skin(Gdx.files.external("PCW/menuskins/Glassy/glassy-ui.json"));
        this.setScreen(new MainMenu(this));
    }

    // Render the screen you set.
    public void render() {
        super.render();
    }

    public void dispose () {
        gameSkin.dispose();
    }

    private void checkManifest() throws IOException {
        BufferedReader br = null;
        try {
            br = Gdx.files.internal("assetManifest.txt").reader(8192, "UTF-8");
            String line;
            while ((line = br.readLine()) != null) {
                // For each line (file) in the manifest.
                // Check presence of assets in external directory and write them if necessary.
                checkFile(line, false);
            }
        }
        finally {
            try { if (br != null) br.close(); } catch(IOException e) {} // closing quietly
        }
    }

    private void checkFile(String inpath, Boolean overwrite) {
        FileHandle dest = Gdx.files.external("PCW/" + inpath);
        // When you have a file, two possible cases.

        if (dest.exists() && !overwrite) {
            // First case: file exists, and overwrite is false. Do nothing.
            System.out.println("Found file in external dir: " + dest.toString());
        } else {
            FileHandle source = Gdx.files.internal(inpath);
            // Second case: file doesn't exist, or overwrite is true (remaining 3 of 4 cases). Copy file.
            try {
                source.copyTo(dest);
                System.out.println("Copied file to external dir: " + dest.toString());
            } catch (GdxRuntimeException e) {
                System.out.println("Runtime exception while copying file to " + dest.toString() + ":\n " + e.toString());
            }
        }
    }

}
