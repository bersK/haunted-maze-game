package game

import rl "vendor:raylib"

TileType :: enum {
	Floor,
	Wall,
}

SentryData :: struct {
	consecutive_frames_seen_player: int,
}

GhostsData :: struct {}

EntityType :: enum {
	Player,
	Sentry,
	Ghost,
}

Direction :: enum {
	Up,
	Down,
	Left,
	Right,
}

DIR_VECTOR := [Direction]Vec2i {
	.Up    = {0, 1},
	.Down  = {0, -1},
	.Left  = {-1, 0},
	.Right = {1, 0},
}

Entity :: struct {
	type:     EntityType,
	location: Vec2i,
	look_dir: Direction,
}

MazeTile :: struct {
	location:    Vec2i,
	tile_type:   TileType,
	occupied_by: ^Entity,
}

reset_player_location :: proc() {
	g_mem.player.location = g_mem.maze_tiles[g_mem.start_tile_id].location * TILE_SIZE
}

setup_maze :: proc() {
	g_mem.maze_tiles, g_mem.current_level_id = next_level()
	reset_player_location()
}

current_level: int
next_level :: proc() -> (maze: [25]MazeTile, level_id: int) {
	@(static)
	maze_levels: [1][25]MazeTile = {
		{
			{location = {0, 0}, tile_type = .Floor, occupied_by = nil},
			{location = {1, 0}, tile_type = .Floor, occupied_by = nil},
			{location = {2, 0}, tile_type = .Floor, occupied_by = nil},
			{location = {3, 0}, tile_type = .Floor, occupied_by = nil},
			{location = {4, 0}, tile_type = .Floor, occupied_by = nil},
			{location = {0, 1}, tile_type = .Floor, occupied_by = nil},
			{location = {1, 1}, tile_type = .Wall, occupied_by = nil},
			{location = {2, 1}, tile_type = .Floor, occupied_by = nil},
			{location = {3, 1}, tile_type = .Floor, occupied_by = nil},
			{location = {4, 1}, tile_type = .Floor, occupied_by = nil},
			{location = {0, 2}, tile_type = .Floor, occupied_by = nil},
			{location = {1, 2}, tile_type = .Wall, occupied_by = nil},
			{location = {2, 2}, tile_type = .Floor, occupied_by = nil},
			{location = {3, 2}, tile_type = .Floor, occupied_by = nil},
			{location = {4, 2}, tile_type = .Floor, occupied_by = nil},
			{location = {0, 3}, tile_type = .Floor, occupied_by = nil},
			{location = {1, 3}, tile_type = .Wall, occupied_by = nil},
			{location = {2, 3}, tile_type = .Wall, occupied_by = nil},
			{location = {3, 3}, tile_type = .Wall, occupied_by = nil},
			{location = {4, 3}, tile_type = .Floor, occupied_by = nil},
			{location = {0, 4}, tile_type = .Floor, occupied_by = nil},
			{location = {1, 4}, tile_type = .Wall, occupied_by = nil},
			{location = {2, 4}, tile_type = .Floor, occupied_by = nil},
			{location = {3, 4}, tile_type = .Floor, occupied_by = nil},
			{location = {4, 4}, tile_type = .Floor, occupied_by = nil},
		},
	}
	current_level += 1
	current_level %= len(maze_levels)

	clear(&g_mem.sentries)
	clear(&g_mem.ghosts)
	clear(&g_mem.sentries_data)
	clear(&g_mem.ghosts_data)

	if current_level == 0 {
		place_sentry_in_maze({4, 0}, .Left)
		place_sentry_in_maze({2, 2}, .Right)
		g_mem.start_tile_id = 20
		g_mem.end_tile_id = 22
	}

	return maze_levels[current_level], current_level
}

place_sentry_in_maze :: proc(loc: Vec2i, dir: Direction) -> bool {
	if g_mem.maze_tiles[loc.y * MAZE_COL + loc.x].occupied_by != nil do return false
	append(&g_mem.sentries, Entity{type = .Sentry, location = loc, look_dir = dir})
	append(&g_mem.sentries_data, SentryData{})
	return true
}

place_ghost_in_maze :: proc(loc: Vec2i) -> bool {
	if g_mem.maze_tiles[loc.y * MAZE_COL + loc.x].occupied_by != nil do return false
	append(&g_mem.ghosts, Entity{type = .Ghost, location = loc})
	append(&g_mem.ghosts_data, GhostsData{})
	return true
}

draw_entity :: proc(e: Entity) {
	color := rl.WHITE
	switch e.type {
	case .Sentry:
		color = rl.RED
	case .Ghost:
		color = rl.WHITE
	case .Player:
		color = rl.GREEN
		rl.DrawRectangleV({f32(e.location.x), f32(e.location.y)}, {TILE_SIZE, TILE_SIZE}, color)
		return
	}
	rl.DrawRectangleV(
		{f32(e.location.x * TILE_SIZE), f32(e.location.y * TILE_SIZE)},
		{TILE_SIZE, TILE_SIZE},
		color,
	)
}
