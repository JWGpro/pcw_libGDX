package com.pcw.game;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.pcw.game.Menus.MainMenu;

import java.io.*;
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
        // When done, change build.gradle to run the manifest generator script, and commit it and the script.

        // Set skin and set screen to the main menu.
        gameSkin = new Skin(Gdx.files.internal("menuskins/Glassy/glassy-ui.json"));
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
        Scanner scanner = new Scanner(new FileInputStream("assetManifest.txt"), "UTF-8");
        try {
            while (scanner.hasNextLine()) {
                // For each line (file) in the manifest.
                // Check presence of assets in external directory and write them if necessary.
                checkFile(scanner.nextLine(), false);
            }
        }
        finally {
            // Something else here? Need to catch something?
            scanner.close();
        }
    }

    private void checkFile(String inpath, Boolean overwrite) {
        File dest = new File(Gdx.files.getExternalStoragePath() + "PCW/" + inpath);
        // When you have a file, two possible cases.

        if (dest.exists() && !overwrite) {
            // First case: file exists, and overwrite is false. Do nothing.
            System.out.println("Found file in external dir: " + dest.toString());
        } else {
            File source = new File(inpath);
            File destDir = new File(dest.getParent());
            // Second case: file doesn't exist, or overwrite is true (remaining 3 of 4 cases). Copy file.
            try {
                copyFile(source, destDir, dest);
                System.out.println("Copied file to external dir: " + dest.toString());
            } catch (IOException e) {
                System.out.println("IO exception while copying file " + dest.toString() + ":\n " + e.toString());
            }
        }
    }

    private void copyFile(File sourceFile, File destDir, File destFile) throws IOException {
        if (!destDir.exists()) {
            // Make the directory if it doesn't exist.
            boolean dirCreated = destDir.mkdirs();
            if (!dirCreated) {
                System.out.println("Directory could not be created: " + destDir.toString());
                return;
            }
        }

        if(!destFile.exists()) {
            // Make the file if it doesn't exist.
            boolean fileCreated = destFile.createNewFile();
            if (!fileCreated) {
                System.out.println("File could not be created: " + destFile.toString());
                return;
            }
        }

        FileChannel src = null;
        FileChannel dst = null;

        try {
            src = new FileInputStream(sourceFile).getChannel();
            dst = new FileOutputStream(destFile).getChannel();
            dst.transferFrom(src, 0, src.size());
        }
        finally {
            try { if (src != null) src.close(); } catch(IOException e) {} // closing quietly
            try { if (dst != null) dst.close(); } catch(IOException e) {} // closing quietly
        }
    }

}
