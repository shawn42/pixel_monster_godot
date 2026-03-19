extends CharacterBody2D

const TILE_SIZE    := 32
const TILE_HALF    := TILE_SIZE / 2
const MOVE_SPEED   := 60.0
const PATH_EPSILON := 4.0

var path_nodes: Array = []  # Array of Vector2i — untyped to allow set() from LevelLoader
var tile_color: Color = Color.GRAY
var source_type: String = "color_source"

const DEBUG_PATH := false  # set true to show path markers and movement logs

var _path_index: int = 0
var _velocity: Vector2 = Vector2.ZERO
var _debug_frames: int = 0

func _ready() -> void:
	set_meta("source_type", source_type)
	set_meta("tile_color",  tile_color)
	# Layer 3 (bitmask 4) — player is layer 2, walls are layer 1.
	# Moving tiles check layer 1 (walls only), so player can't block them.
	# Player mask includes layer 3, so player can still stand on moving tiles.
	# Crush detection is manual via _boxes_touch.
	collision_layer = 4
	collision_mask  = 1

func _physics_process(delta: float) -> void:
	if path_nodes.is_empty():
		if DEBUG_PATH and _debug_frames == 0:
			print("[MovableTile] path_nodes EMPTY at ", position)
			_debug_frames += 1
		return

	if DEBUG_PATH and _debug_frames < 3:
		print("[MovableTile] pos=", position, " path_nodes=", path_nodes, " idx=", _path_index)
		_debug_frames += 1

	var target_grid := path_nodes[_path_index] as Vector2i
	var target_world := Vector2(
		target_grid.x * TILE_SIZE + TILE_HALF,
		target_grid.y * TILE_SIZE + TILE_HALF
	)

	var to_target := target_world - position
	var dist      := to_target.length()

	if dist < PATH_EPSILON:
		_path_index = (_path_index + 1) % path_nodes.size()
		target_grid  = path_nodes[_path_index] as Vector2i
		target_world = Vector2(target_grid.x * TILE_SIZE + TILE_HALF,
							   target_grid.y * TILE_SIZE + TILE_HALF)
		to_target    = target_world - position
		dist         = to_target.length()

	if dist > 0:
		var dir      := to_target / dist
		_velocity    = dir * MOVE_SPEED
		set_meta("velocity", _velocity)
	else:
		_velocity = Vector2.ZERO
		set_meta("velocity", _velocity)

	# Move tile directly along path (no physics — paths are predefined)
	position += _velocity * delta

	var player: Node2D = _get_player()
	if player and _is_player_crushed(player):
		player._die()
		return

	if source_type == "death" or DEBUG_PATH:
		queue_redraw()

func _is_player_crushed(player: Node2D) -> bool:
	if not _boxes_touch(position, Vector2(16,16), player.position, Vector2(14,14), 0):
		return false
	var level := _get_level()
	if not level:
		return false
	var pw   := player.position
	var pw_x := pw.x
	var pw_y := pw.y
	var w    := 7.0
	var h    := 7.0
	return level.is_blocked(level.world_to_grid(Vector2(pw_x - w, pw_y - h))) or \
		   level.is_blocked(level.world_to_grid(Vector2(pw_x + w, pw_y - h))) or \
		   level.is_blocked(level.world_to_grid(Vector2(pw_x - w, pw_y + h))) or \
		   level.is_blocked(level.world_to_grid(Vector2(pw_x + w, pw_y + h)))

func _draw() -> void:
	if DEBUG_PATH and not path_nodes.is_empty():
		for i in path_nodes.size():
			var g := path_nodes[i] as Vector2i
			var world_pos := Vector2(g.x * TILE_SIZE + TILE_HALF, g.y * TILE_SIZE + TILE_HALF)
			var local_pos := world_pos - position
			# Filled square: dim version of tile_color to distinguish from the tile itself
			draw_rect(Rect2(local_pos - Vector2(6, 6), Vector2(12, 12)), Color(tile_color.r, tile_color.g, tile_color.b, 0.35))
			# White border so it's visible against any background
			draw_rect(Rect2(local_pos - Vector2(6, 6), Vector2(12, 12)), Color.WHITE, false, 1.0)
			# Number the first and last node
			if i == 0:
				draw_rect(Rect2(local_pos - Vector2(3, 3), Vector2(6, 6)), Color.GREEN)
			elif i == path_nodes.size() - 1:
				draw_rect(Rect2(local_pos - Vector2(3, 3), Vector2(6, 6)), Color.RED)

	if source_type == "death":
		for i in 50:
			var rx := randf_range(-16.0, 16.0)
			var ry := randf_range(-16.0, 16.0)
			var rw := randf_range(2.0, 5.0)
			var rh := randf_range(2.0, 5.0)
			var rc := Color(randf_range(0.2, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0),
							randf_range(0.86, 1.0))
			draw_rect(Rect2(rx, ry, rw, rh), rc)
	else:
		draw_rect(Rect2(-16, -16, 32, 32), tile_color)

func _get_player() -> Node2D:
	var level := _get_level()
	return level.player if level else null

func _get_level() -> Node2D:
	var p := get_parent()
	if p.get_script() and p.get_script().get_global_name() == "Level":
		return p
	return null

static func _boxes_touch(a: Vector2, ah: Vector2, b: Vector2, bh: Vector2, buf: float) -> bool:
	return absf(a.x - b.x) <= (ah.x + bh.x + buf) and absf(a.y - b.y) <= (ah.y + bh.y + buf)
