// This file is compiled as part of the `odin.dll` file. It contains the
// procs that `game.exe` will call, such as:
//
// game_init: Sets up the game state
// game_update: Run once per frame
// game_shutdown: Shuts down game and frees memory
// game_memory: Run just before a hot reload, so game.exe has a pointer to the
//		game's memory.
// game_hot_reloaded: Run after a hot reload so that the `g_mem` global variable
//		can be set to whatever pointer it was in the old DLL.

package game

import "core:fmt"
import rl "vendor:raylib"

TILE_SIZE :: 16
MAZE_ROW :: 5
MAZE_COL :: 5

PixelWindowHeight :: 10 * TILE_SIZE + TILE_SIZE / 2

GameMemory :: struct {
	maze_tiles:       [MAZE_COL * MAZE_ROW]MazeTile,
	start_tile_id:    int,
	end_tile_id:      int,
	current_level_id: int,
	player:           Player,
	sentries:         [dynamic]Entity,
	sentries_data:    [dynamic]SentryData,
	ghosts:           [dynamic]Entity,
	ghosts_data:      [dynamic]GhostsData,
	level_metadata:   LevelData,
	level_texture:    rl.RenderTexture,
	tilemap_texture:  rl.Texture,
}

LevelData :: struct {
	collision_tiles:      [dynamic]u8,
	tiles:                [dynamic]tile,
	pickups:              [dynamic]Pickup,
	broken_walls:         [dynamic]BrokenWallLocation,
	level_start_location: Vec2i,
	level_end_location:   Vec2i,
	grid_x:               int,
	grid_y:               int,
	cell_size:            int,
	entities:             [dynamic]Entity,
}

g_mem: ^GameMemory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	target_ := vec2_from_vec2i(g_mem.player.location)

	return {zoom = h / PixelWindowHeight, target = target_, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PixelWindowHeight}
}

update :: proc() {
	update_player()
}


draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.BLACK)
	rl.BeginMode2D(game_camera())
	{
		rect_src: rl.Rectangle
		rect_dst: rl.Rectangle
		rect_src.width = f32(g_mem.level_metadata.cell_size)
		rect_src.height = f32(g_mem.level_metadata.cell_size)
		rect_dst = rect_src
		for t in g_mem.level_metadata.tiles {
			// t.
			rect_src.x = t.src.x
			rect_src.y = t.src.y
			rect_dst.x = t.dst.x
			rect_dst.y = t.dst.y
			rl.DrawTexturePro(g_mem.tilemap_texture, rect_src, rect_dst, {}, 0, rl.WHITE)
		}

		for g in g_mem.ghosts {
			draw_entity(g)
		}

		for s in g_mem.sentries {
			draw_entity(s)
		}
		render_player()
	}
	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())
	{
		rl.DrawText(fmt.ctprintf("player_pos: %v", g_mem.player.location), 5, 5, 8, rl.WHITE)
	}
	rl.EndMode2D()
}

@(export)
game_update :: proc() -> bool {
	update()
	draw()
	return !rl.WindowShouldClose()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, "Ghost Maze")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)

	rl.SetExitKey(.KEY_NULL)
}

@(export)
game_init :: proc() {
	g_mem = new(GameMemory)

	g_mem^ = GameMemory{}

	game_hot_reloaded(g_mem)

	if g_mem.tilemap_texture.id != 0 {
		rl.UnloadTexture(g_mem.tilemap_texture)
	}
	g_mem.tilemap_texture = rl.LoadTexture(TILEMAP_PACKED_PATH)
	setup_maze()
}

@(export)
game_shutdown :: proc() {
	// NOTE: This is terrible, think of something better in the future
	delete(g_mem.sentries)
	for ed in g_mem.sentries_data {
		delete(ed.target_points)
	}
	delete(g_mem.sentries_data)
	delete(g_mem.ghosts)
	delete(g_mem.ghosts_data)

	delete(g_mem.level_metadata.broken_walls)
	delete(g_mem.level_metadata.collision_tiles)
	delete(g_mem.level_metadata.tiles)
	delete(g_mem.level_metadata.pickups)
	delete(g_mem.level_metadata.entities)

	rl.UnloadTexture(g_mem.tilemap_texture)

	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(GameMemory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^GameMemory)(mem)
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}
