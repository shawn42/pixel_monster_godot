extends SceneTree

const PathWalker = preload("res://scripts/PathWalker.gd")

func _init() -> void:
	_test_straight_line()
	_test_square_loop()
	_test_single_node()
	print("All PathWalker tests passed!")
	quit(0)

func _test_single_node() -> void:
	# single node → just that node in a loop
	var locs: Array[Vector2i] = [Vector2i(0, 0)]
	var path := PathWalker.build_path(locs, Vector2i(0, 0))
	assert(path.size() == 1, "single node size")
	assert(path[0] == Vector2i(0, 0), "single node value")
	print("  _test_single_node: PASS")

func _test_straight_line() -> void:
	# horizontal line: (0,0) (1,0) (2,0)
	var locs: Array[Vector2i] = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)]
	var path := PathWalker.build_path(locs, Vector2i(0, 0))
	assert(path.size() == 3, "line size == 3, got %d" % path.size())
	# all three cells should appear
	assert(Vector2i(0,0) in path, "line contains (0,0)")
	assert(Vector2i(1,0) in path, "line contains (1,0)")
	assert(Vector2i(2,0) in path, "line contains (2,0)")
	print("  _test_straight_line: PASS")

func _test_square_loop() -> void:
	# 2x2 square: (0,0)(1,0)(0,1)(1,1)
	var locs: Array[Vector2i] = [
		Vector2i(0,0), Vector2i(1,0),
		Vector2i(0,1), Vector2i(1,1)
	]
	var path := PathWalker.build_path(locs, Vector2i(0, 0))
	assert(path.size() == 4, "square size == 4")
	# each step should be adjacent to the previous
	for i in path.size():
		var a: Vector2i = path[i]
		var b: Vector2i = path[(i + 1) % path.size()]
		var dist := absi(a.x - b.x) + absi(a.y - b.y)
		assert(dist == 1, "consecutive cells adjacent: %s → %s" % [a, b])
	print("  _test_square_loop: PASS")
