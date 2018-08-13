package com.pcw.game.desktop;

import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import com.pcw.game.PCW;

public class DesktopLauncher {
	public static void main (String[] arg) {
		LwjglApplicationConfiguration config = new LwjglApplicationConfiguration();
        config.title = "PC Wars";
		config.width = 480;
		config.height = 320;

//		config.vSyncEnabled = false; // Setting to false disables vertical sync
//		config.foregroundFPS = 0; // Setting to 0 disables foreground fps throttling
//		config.backgroundFPS = 0; // Setting to 0 disables background fps throttling

		new LwjglApplication(new PCW(), config);
	}
}
