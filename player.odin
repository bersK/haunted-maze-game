package game

import rl "vendor:raylib"

Player :: struct {
	using _: Entity,
}

update_player :: proc() {
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
render_player :: proc() {
	draw_entity(g_mem.player)
}
