package com.pcw.game;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.pcw.game.Menus.MainMenu;

import java.io.*;
import java.nio.channels.FileChannel;

public class PCW extends Game {

    static public Skin gameSkin;

    public void create() {
        // Check presence of assets in external directory and write them if necessary.
        // "D:/Desktop/TheProjects/Programming/~libGDX/pcw/android/assets"

        // Either manifest,
        // separate APK/JAR/IDE handling,
        // zipped up assets...would this involve loading all assets into RAM at once? Could be a problem.
        //  tar/jar...non-compressed so I can just order the files and grab them as necessary rather than load all...
        System.out.println(Gdx.app.getType());

//        checkFiles(new File(Gdx.files.internal(".").toString()), false);
//        checkFiles(new File(Gdx.files.classpath(".").toString()), false);
//        checkFiles(new File(Gdx.files.local(".").toString()), false);

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

    private void checkFiles(final File searchpath, Boolean overwrite) {
        File[] files = searchpath.listFiles();

        if (files == null) {
            // Handle path that is not a directory, or other error...
            System.out.println("listFiles() returned null for search path argument: " + searchpath.toString());
        } else {
            // Normal case.
            for (File file : files) {

                // Get the trailing bit for internal-external operations.
                String path = file.toString();
                String expath = Gdx.files.getExternalStoragePath();

                if (file.isDirectory()) {
                    // If the path is a directory rather than a file, recurse.
                    checkFiles(file, overwrite);
                } else {
                    // When you have a file, two possible cases.
                    File source = new File(path);
                    System.out.println(source.toString());
                    File dest = new File(expath + "PCW/" + path);
                    System.out.println(dest.toString());
                    File destDir = new File(dest.getParent());

                    if (dest.exists() && !overwrite) {
                        // First case: file exists, and overwrite is false. Do nothing.
                        System.out.println("Found file in external dir: " + path);
                    } else {
                        // Second case: file doesn't exist, or overwrite is true (remaining 3 of 4 cases). Copy file.
                        try {
                            copyFile(source, destDir, dest);
                            System.out.println("Copied file to external dir: " + path);
                        } catch (IOException e) {
                            System.out.println("Exception while copying file " + path + ":\n " + e.toString());
                        }

                    }
                }
            }
        }
    }

    private void copyFile(File sourceFile, File destDir, File destFile) throws IOException {
        if (!destDir.exists()) {
            boolean dirCreated = destDir.mkdirs();
            if (!dirCreated) {
                System.out.println("Directory could not be created: " + destDir.toString());
                return;
            }
        }

        if(!destFile.exists()) {
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
