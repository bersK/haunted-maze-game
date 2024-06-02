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

TILE_SIZE :: 40
MAZE_ROW :: 5
MAZE_COL :: 5

PixelWindowHeight :: 10 * TILE_SIZE + TILE_SIZE / 2

GameMemory :: struct {
	maze_tiles:       [MAZE_COL * MAZE_ROW]MazeTile,
	start_tile_id:    int,
	end_tile_id:      int,
	current_level_id: int,
	player:           Entity,
	sentries:         [dynamic]Entity,
	sentries_data:    [dynamic]SentryData,
	ghosts:           [dynamic]Entity,
	ghosts_data:      [dynamic]GhostsData,
}
g_mem: ^GameMemory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	target_ :=
		(vec2_from_vec2i(g_mem.maze_tiles[len(g_mem.maze_tiles) - 1].location * TILE_SIZE) / 2) +
		TILE_SIZE / 2

	return {zoom = h / PixelWindowHeight, target = target_, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PixelWindowHeight}
}

update :: proc() {
	input: Vec2i

	if rl.IsKeyReleased(.UP) {
		input.y -= TILE_SIZE
	}
	if rl.IsKeyReleased(.DOWN) {
		input.y += TILE_SIZE
	}
	if rl.IsKeyReleased(.LEFT) {
		input.x -= TILE_SIZE
	}
	if rl.IsKeyReleased(.RIGHT) {
		input.x += TILE_SIZE
	}

	if rl.IsKeyPressed(.G) {
		place_ghost_in_maze(g_mem.player.location / TILE_SIZE)
		reset_player_location()
	}

	if rl.IsKeyReleased(.L) {
		g_mem.maze_tiles, g_mem.current_level_id = next_level()
		reset_player_location()
	}

	g_mem.player.location += input
}


draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(game_camera())

	for tile in g_mem.maze_tiles {
		color := rl.DARKGRAY if tile.tile_type == .Floor else rl.DARKBROWN
		rl.DrawRectangleV(
			position = {f32(tile.location.x * TILE_SIZE), f32(tile.location.y * TILE_SIZE)},
			size = {TILE_SIZE, TILE_SIZE},
			color = color,
		)
	}

	for g in g_mem.ghosts {
		draw_entity(g)
	}

	for s in g_mem.sentries {
		draw_entity(s)
	}

	draw_entity(g_mem.player)

	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())
	rl.DrawText(fmt.ctprintf("player_pos: %v", g_mem.player.location), 5, 5, 8, rl.WHITE)
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

	setup_maze()
}

@(export)
game_shutdown :: proc() {
	delete(g_mem.sentries)
	delete(g_mem.sentries_data)
	delete(g_mem.ghosts)
	delete(g_mem.ghosts_data)
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

