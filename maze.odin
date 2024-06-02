package game

import "core:log"
import ldtk "third_party:odin-ldtk"
import rl "vendor:raylib"

ENameStart :: "Start"
ENameEnd :: "End"
ENameSentry :: "Sentry"
ENameWallPortal :: "WallPortal"
ENameSoulPickup :: "SoulPickup"
ENameGenericPickup :: "GenericPickup"

TileType :: enum {
	Floor,
	Wall,
}

SentryData :: struct {
	consecutive_frames_seen_player: int,
	target_points:                  []Vec2i,
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

tile :: struct {
	src:    rl.Vector2,
	dst:    rl.Vector2,
	flip_x: bool,
	flip_y: bool,
}

PickupType :: enum {
	Soul,
	Generic,
}

Pickup :: struct {
	location: Vec2i,
	type:     PickupType,
}

BrokenWallLocation :: distinct Vec2i

collect_tiles_from_ldtk_project :: proc(
	project: ^ldtk.Project,
	level_idx: int = 0,
) -> (
	level_metadata: LevelData,
	success: bool,
) {
	if len(project.levels) - 1 < level_idx {
		log.debug("No such level idx in ldtk project")
		return
	}

	tile_offset: rl.Vector2
	tile_size := 16
	tile_columns := -1
	tile_rows := -1

	level_metadata.cell_size = tile_size
	using level_metadata

        clear(&g_mem.sentries_data)
	sentry_data := &g_mem.sentries_data

	level := &project.levels[level_idx]
	for layer in level.layer_instances {
		switch layer.type {
		case .IntGrid:
			if layer.identifier != "Collisions" do continue

			log.debug("This is the collision layer")

			tile_columns = layer.c_width
			tile_rows = layer.c_height
			level_metadata.grid_x = tile_rows
			level_metadata.grid_y = tile_columns


			reserve(
				&collision_tiles,
				len(collision_tiles) + (tile_columns * tile_rows),
			)
			tile_offset.x = f32(layer.px_total_offset_x)
			tile_offset.y = f32(layer.px_total_offset_y)

			for val in layer.int_grid_csv {
				append(&collision_tiles, u8(val))
			}


			reserve(&tiles, len(tiles) + len(layer.auto_layer_tiles))

			t: tile
			multiplier: f32 = f32(tile_size) / f32(layer.grid_size)
			for val in layer.auto_layer_tiles {
				t.dst.x = f32(val.px.x) * multiplier
				t.dst.y = f32(val.px.y) * multiplier
				t.src.x = f32(val.src.x)
				f := val.f
				t.src.y = f32(val.src.y)
				t.flip_x = bool(f & 1)
				t.flip_y = bool(f & 2)
				append(&tiles, t)
			}

		case .Entities:
			log.debug("This is the entities layer")

			if entities == nil {
				entities = make([dynamic]Entity, len(layer.entity_instances))
			} else {
				clear(&entities)
			}
			for entity_instance, ei in layer.entity_instances {
				if entity_instance.identifier == ENameSentry {
					ed := &entities[ei]
					ed^ = Entity {
						type     = .Sentry,
						location = entity_instance.grid,
						look_dir = .Down,
					}
					append(sentry_data, SentryData{})

					for fi in entity_instance.field_instances {
						if fi.identifier == "Direction" {
							if dir, ok := parse_direction_ldtk(fi); ok {
								ed.look_dir = dir
							}
						}
						if fi.identifier == "Point" {
							if ok := parse_sentry_points_ldtk(fi, sentry_data); ok {

							}
						}
					}
				}
				if entity_instance.identifier == ENameStart {
				}
				if entity_instance.identifier == ENameEnd {
				}
				if entity_instance.identifier == ENameWallPortal {
				}
				if entity_instance.identifier == ENameSoulPickup {
				}
				if entity_instance.identifier == ENameGenericPickup {
				}
			}

			log.debug(sentry_data)

		case .Tiles:

		case .AutoLayer:
			if layer.identifier != "Floors" do continue

			log.debug("This is the floor layer")

			tile_columns = layer.c_width
			tile_rows = layer.c_height
			//tile_size = 720 / tile_rows
			reserve(
				&collision_tiles,
				len(collision_tiles) + (tile_columns * tile_rows),
			)

			tile_offset.x = f32(layer.px_total_offset_x)
			tile_offset.y = f32(layer.px_total_offset_y)

			for val in layer.int_grid_csv {
				append(&collision_tiles, u8(val))
			}


			t: tile
			reserve(&tiles, len(tiles) + len(layer.auto_layer_tiles))

			multiplier: f32 = f32(tile_size) / f32(layer.grid_size)
			for val in layer.auto_layer_tiles {
				t.dst.x = f32(val.px.x) * multiplier
				t.dst.y = f32(val.px.y) * multiplier
				t.src.x = f32(val.src.x)
				f := val.f
				t.src.y = f32(val.src.y)
				t.flip_x = bool(f & 1)
				t.flip_y = bool(f & 2)
				append(&tiles, t)
			}
		}
	}
	success = true
	return
}

load_level_ldtk :: proc(level_idx: int = 0) {
	project: Maybe(ldtk.Project)

	project = ldtk.load_from_memory(ldtk_project, context.temp_allocator)
	if proj, pok := project.?; pok {
		success: bool
		g_mem.level_metadata, success = collect_tiles_from_ldtk_project(&proj, level_idx)
		if !success {
			return
		}

		g_mem.current_level_id = level_idx

		// g_mem.level_texture = rl.LoadRenderTexture(
		// 	i32(g_mem.level_metadata.grid_x * g_mem.level_metadata.cell_size),
		// 	i32(g_mem.level_metadata.grid_y * g_mem.level_metadata.cell_size),
		// )

		// rl.BeginDrawing()
		// defer rl.EndDrawing()

		// rl.BeginTextureMode(g_mem.level_texture)
		// rect_src: rl.Rectangle
		// rect_dst: rl.Rectangle
		// for t in g_mem.level_metadata.tiles {
		// 	// t.
		// 	rect_src.x = t.src.x
		// 	rect_src.y = t.src.y
		// 	rect_dst.x = t.dst.x
		// 	rect_dst.y = t.dst.y
		// 	rl.DrawTexturePro(g_mem.tilemap_texture, rect_src, rect_dst, {}, 0, rl.WHITE)
		// }
		// rl.EndTextureMode()
	}
}

current_level: int
next_level :: proc() -> (maze: [25]MazeTile, level_id: int) {
	@(static)
	maze_levels: [5][25]MazeTile =  {
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
		{},
		{},
		{},
		{},
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

	load_level_ldtk(current_level)
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
