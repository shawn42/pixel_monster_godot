extends AnimatableBody2D

const TILE_SIZE    := 32
const TILE_HALF    := TILE_SIZE / 2
const MOVE_SPEED   := 1.0
const PATH_EPSILON := 1.0

var path_nodes: Array[Vector2i] = []
var tile_color: Color = Color.GRAY
var source_type: String = "color_source"

var _path_index: int = 0
var _velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_meta("source_type", source_type)
	set_meta("tile_color",  tile_color)

func _physics_process(delta: float) -> void:
	if path_nodes.is_empty():
		return

	var target_grid := path_nodes[_path_index]
	var target_world := Vector2(
		target_grid.x * TILE_SIZE + TILE_HALF,
		target_grid.y * TILE_SIZE + TILE_HALF
	)

	var to_target := target_world - position
	var dist      := to_target.length()

	if dist < PATH_EPSILON:
		_path_index = (_path_index + 1) % path_nodes.size()
		target_grid  = path_nodes[_path_index]
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

	# Move tile one step and check for player crush
	var vel_x := _velocity.x
	var vel_y := _velocity.y
	var x_steps := int(absf(vel_x))
	var y_steps := int(absf(vel_y))
	var x_sign  := sign(vel_x) as int
	var y_sign  := sign(vel_y) as int

	var player: Node2D = _get_player()

	for _i in x_steps:
		position.x += x_sign
		if player and _is_player_crushed(player):
			player._die()
			return

	for _i in y_steps:
		position.y += y_sign
		if player and _is_player_crushed(player):
			player._die()
			return

	queue_redraw()

func _is_player_crushed(player: Node2D) -> bool:
	if not _boxes_touch(position, Vector2(8,8), player.position, Vector2(7,7), 0):
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
	draw_rect(Rect2(-8, -8, 16, 16), tile_color)

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
