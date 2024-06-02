# The Haunted Maze
A maze game about traversing a maze by strategically turning into a ghost.

# Running
Download the release build from the release section.

# Building

If you want to build the game yourself you will need a couple of things:

1. An Odinlang compiler
2. source code


You can get the odin compiler from [here](https://github.com/odin-lang/Odin/releases/tag/dev-2024-05)
and the source code by just clicking the green button 'Code' & then 'Download ZIP'.

Once downloaded both files, unzip the game somewhere (for this example I will place it at the base of the `C:\` drive) & create a toolchain folder inside the game folder. Place the contents of the compiler zip such that `odin.exe` is inside the `toolchain` folder as shown below.

```cmd
C:\HAUNTEDMAZE.
├───.vscode
├───build
├───main_hot_reload
├───main_release
├───scripts
├───shaders
├───third_party
│   └───...
└───toolchain
│   └───odin.exe
```

To build the game run the build_release_local_odin.bat script from the root of the project.
```cmd
C:\HAUNTEDMAZE> scripts\build_release_local_odin.bat
```

To start the game run it from the command line or open the `build` folder in your File Explorer:
```cmd
C:\HAUNTEDMAZE> cd build
C:\HAUNTEDMAZE\BUILD> game_release.exe
```

# Credits

Tools used:
* Project template: Odin + Raylib hot-reloading template by Karl Zylinksi([template](https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template/tree/main))
* Tilemap editor: LDtk([ldtk](https://ldtk.io/))
* LDtk output parser lib for odin by Jakub Tomsu: odin-ldtk([odin-ldtk](https://github.com/jakubtomsu/odin-ldtk))
* Tileset: 1Bit platformer pack by Kenney([tileset](https://kenney.nl/assets/1-bit-platformer-pack))
