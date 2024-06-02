package game

import "core:encoding/json"
import ldtk "third_party:odin-ldtk"

parse_direction_ldtk :: proc(fi: ldtk.Field_Instance) -> (dir: Direction, ok: bool) {
	dir_str, sok := fi.value.(json.String);if !sok {
		return dir, false
	}

	if dir_str == "Down" do dir = .Down
	if dir_str == "Right" do dir = .Right
	if dir_str == "Left" do dir = .Left
	if dir_str == "Up" do dir = .Up
	return dir, true
}

parse_sentry_points_ldtk :: proc(fi: ldtk.Field_Instance, sentry_data: ^[dynamic]SentryData) -> bool {
	points, pok := fi.value.(json.Array);if !pok {
		return false
	}

	parsed_points := make([]Vec2i, len(points))
	for p, pi in points {
		pv := p.(json.Object)
		parsed_points[pi].x = int(pv["cx"].(json.Integer))
		parsed_points[pi].y = int(pv["cy"].(json.Integer))
	}
	data_idx := len(sentry_data) - 1
	sentry_data[data_idx].target_points = parsed_points
        return true
}
