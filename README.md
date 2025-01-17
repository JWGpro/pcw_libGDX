*This repository is deprecated; development of this project moved to a new implementation [pcwkt](https://github.com/JWGpro/pcwkt) on 2022-10-28.*

# pcw_libGDX

A work-in-progress Advance Wars clone written in Java and Lua with libGDX, for PC and Android. Developed July 2017 - January 2019, then January 2022 until the deprecation date.

Java was used for "engine" logic, while Lua was used to implement game logic, to allow for user-made mods. The codebase was refactored multiple times.

Some features implemented:
- Attempts at design patterns; [Command](https://gameprogrammingpatterns.com/command.html) for "replays" (the ability to play back and rewind played games), [State](https://gameprogrammingpatterns.com/state.html).
- [A* pathfinding](https://en.wikipedia.org/wiki/A*_search_algorithm) written from scratch for evaluating valid routes
- Input mapping, multiplexed event handling
- A primitive map maker which can serialise to files

Pertinent Java files can be found in:
[core/src/com/pcw/game](https://github.com/JWGpro/pcw_libGDX/tree/master/core/src/com/pcw/game)

Pertinent Lua files can be found in:
[android/assets/gamemodes](https://github.com/JWGpro/pcw_libGDX/tree/master/android/assets/gamemodes)

The entry point is [here](https://github.com/JWGpro/pcw_libGDX/blob/master/desktop/src/com/pcw/game/desktop/DesktopLauncher.java).

# Importing and Running

Mainly the below:
https://libgdx.com/dev/import-and-running/

Though, a pre-launch task should be configured to run the Python 3 script assetManifestGen.py:
$ python3 assetManifestGen.py
This copies assets and scripts to a folder in the user's home directory to make them available at runtime.
Probably going to be rethought.

# License

Licensed under the GNU Affero General Public License 3 or any later version at your choice.

SPDX-License-Identifier: AGPL-3.0-or-later
