extends SceneTree

const LevelScript = preload("res://scripts/Level.gd")

func _init() -> void:
	_test_is_blocked()
	_test_in_exit()
	_test_has_exit_color()
	print("All Level tests passed!")
	quit(0)

func _test_is_blocked() -> void:
	var level: Node2D = _make_level()
	level.tile_map[Vector2i(2, 3)] = true
	assert(level.is_blocked(Vector2i(2, 3)), "blocked tile returns true")
	assert(!level.is_blocked(Vector2i(0, 0)), "empty tile returns false")
	print("  _test_is_blocked: PASS")

func _test_in_exit() -> void:
	var level: Node2D = _make_level()
	level.exit_grid_pos = Vector2i(5, 5)
	# player center exactly on exit grid cell center = col*32+16, row*32+16
	var center := Vector2(5 * 32 + 16, 5 * 32 + 16)
	assert(level.in_exit(center, Vector2(7, 7)), "player on exit")
	var far := Vector2(0, 0)
	assert(!level.in_exit(far, Vector2(7, 7)), "player far from exit")
	print("  _test_in_exit: PASS")

func _test_has_exit_color() -> void:
	var level: Node2D = _make_level()
	level.exit_color = Color(0.5, 0.5, 0.5, 1.0)
	# within tolerance (avg diff < 20/255 ≈ 0.078)
	var close := Color(0.5, 0.5, 0.5, 1.0)
	assert(level.has_exit_color(close), "exact match")
	# outside tolerance
	var far := Color(1.0, 0.0, 0.0, 1.0)
	assert(!level.has_exit_color(far), "far color fails")
	print("  _test_has_exit_color: PASS")

func _make_level() -> Node2D:
	var l: Node2D = LevelScript.new()
	l.tile_map = {}
	l.exit_color = Color.BLACK
	l.exit_grid_pos = Vector2i(0, 0)
	return l
