package game

LDTK_PROJECT_PATH :: "./assets/ghost_game.ldtk"
TILEMAP_PACKED_PATH :: "./assets/monochrome_tilemap_packed.png"
TILEMAP_TRANSPARENT_PACKED_PATH :: "./assets/monochrome_tilemap_transparent_packed.png"

ldtk_project :: #load(LDTK_PROJECT_PATH, []u8)
tilemap_packed :: #load(TILEMAP_PACKED_PATH, []u8)
tilemap_transparent_packed :: #load(TILEMAP_TRANSPARENT_PACKED_PATH, []u8)
