extends SceneTree

const MovableTileScene = preload("res://scenes/tiles/MovableTile.tscn")
const LevelLoader = preload("res://scripts/LevelLoader.gd")
const PathWalker  = preload("res://scripts/PathWalker.gd")

func _init() -> void:
	_test_path_nodes_set_via_variant()
	_test_path_nodes_set_directly()
	_test_find_path_locs_with_adjacent_pixels()
	_test_build_path_returns_typed()
	_test_tile_moves_when_physics_process_called()
	print("All MovableTile tests passed!")
	quit(0)

## Does tile.set("path_nodes", typed_array) actually stick?
func _test_path_nodes_set_via_variant() -> void:
	var tile: Node2D = MovableTileScene.instantiate()
	var path: Array[Vector2i] = [Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]
	tile.set("path_nodes", path)
	var result = tile.get("path_nodes")
	assert(result != null, "path_nodes not null after set()")
	assert(result.size() == 3, "path_nodes size == 3 after set(), got %d" % result.size())
	print("  _test_path_nodes_set_via_variant: PASS (size=%d)" % result.size())
	tile.free()

## Does directly assigning path_nodes on an untyped Array work?
func _test_path_nodes_set_directly() -> void:
	var tile: Node2D = MovableTileScene.instantiate()
	var path: Array = [Vector2i(5,0), Vector2i(6,0)]
	tile.set("path_nodes", path)
	var result = tile.get("path_nodes")
	assert(result.size() == 2, "untyped array path_nodes size == 2, got %d" % result.size())
	print("  _test_path_nodes_set_directly: PASS (size=%d)" % result.size())
	tile.free()

## Does find_path_locs find adjacent semi-transparent pixels?
func _test_find_path_locs_with_adjacent_pixels() -> void:
	# Build a tiny in-memory image: 3 wide, 2 tall (1 command row + 1 tile row)
	# Row 0 (command): all transparent
	# Row 1 (tile): col0=opaque red, col1=semi-transparent red, col2=transparent
	var img := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 1, Color(1, 0, 0, 1))      # opaque start tile
	img.set_pixel(1, 1, Color(1, 0, 0, 0.5))    # semi-transparent path pixel
	img.set_pixel(2, 1, Color(0, 0, 0, 0))      # transparent

	var locs := LevelLoader.find_path_locs(img, Vector2i(0, 0), Color(1, 0, 0, 1))
	assert(locs.size() == 2, "find_path_locs found %d locs, expected 2" % locs.size())
	assert(Vector2i(0,0) in locs, "locs contains start (0,0)")
	assert(Vector2i(1,0) in locs, "locs contains path pixel (1,0)")
	print("  _test_find_path_locs_with_adjacent_pixels: PASS (locs=%d)" % locs.size())

## Does PathWalker.build_path return Array[Vector2i] or plain Array?
func _test_build_path_returns_typed() -> void:
	var locs: Array[Vector2i] = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)]
	var path := PathWalker.build_path(locs, Vector2i(0,0))
	assert(path.size() == 3, "build_path size == 3, got %d" % path.size())
	# Confirm elements are actually Vector2i
	var first = path[0]
	assert(first is Vector2i, "path[0] is Vector2i, got: %s" % type_string(typeof(first)))
	# Now confirm set() on a tile works with this exact return value
	var tile: Node2D = MovableTileScene.instantiate()
	tile.set("path_nodes", path)
	var result = tile.get("path_nodes")
	assert(result.size() == 3, "path from build_path set on tile, size==3, got %d" % result.size())
	print("  _test_build_path_returns_typed: PASS (size=%d, element_type=%s)" % [result.size(), type_string(typeof(path[0]))])
	tile.free()

## Does the tile actually move when _physics_process is driven manually?
func _test_tile_moves_when_physics_process_called() -> void:
	var tile: Node2D = MovableTileScene.instantiate()
	# Set a two-node horizontal path: start at grid (0,0), next at grid (1,0)
	tile.set("path_nodes", [Vector2i(0, 0), Vector2i(1, 0)])
	# Place tile at world position of grid (0,0)
	tile.position = Vector2(16, 16)  # 0*32+16, 0*32+16
	var pos_before := tile.position

	# Call _physics_process directly to simulate one tick
	tile.call("_physics_process", 1.0 / 60.0)
	var pos_after := tile.position

	print("  position before: %s  after: %s  delta: %s" % [pos_before, pos_after, pos_after - pos_before])
	assert(pos_after != pos_before, "tile position changed after _physics_process")
	print("  _test_tile_moves_when_physics_process_called: PASS")
	tile.free()
