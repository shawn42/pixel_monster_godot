extends SceneTree

const LevelLoaderScript = preload("res://scripts/LevelLoader.gd")

func _init() -> void:
	var loader = LevelLoaderScript.new()
	var level = loader.load_level("res://levels/level1.png")
	assert(level != null, "level loaded")
	assert(level.map_width > 0, "has width")
	assert(level.map_height > 0, "has height")
	assert(level.player != null, "has player spawn")
	assert(level.exit_node != null, "has exit")
	print("Level loaded: %dx%d" % [level.map_width, level.map_height])
	print("Color sources: %d" % level.color_sources.size())
	print("Moving tiles: %d" % level.moving_tiles.size())
	print("Exit color: %s" % level.exit_color)
	print("test_level_loading: PASS")
	quit(0)
