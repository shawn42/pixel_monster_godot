extends SceneTree

const LevelLoader = preload("res://scripts/LevelLoader.gd")

func _init() -> void:
	_test_parse_commands_empty()
	_test_parse_commands_bouncy()
	_test_parse_commands_black_hole()
	_test_parse_commands_rainbow()
	_test_pixel_to_tile_white_is_player()
	_test_pixel_to_tile_black_is_exit()
	_test_pixel_to_tile_color_source()
	_test_find_path_locs_single()
	_test_find_path_locs_path()
	print("All LevelLoader tests passed!")
	quit(0)

func _test_parse_commands_empty() -> void:
	# top row: [exit_color, transparent] → no commands
	var img := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.RED)         # exit color
	img.set_pixel(1, 0, Color(0,0,0,0))    # transparent → no commands
	img.set_pixel(2, 0, Color(0,0,0,0))
	# fill rest with transparent
	var result := LevelLoader.parse_commands(img)
	assert(result.exit_color == Color.RED, "exit color")
	assert(result.special_tiles.is_empty(), "no commands → empty special_tiles")
	print("  _test_parse_commands_empty: PASS")

func _test_parse_commands_bouncy() -> void:
	# command: [BLUE, marker_color] → BouncyTile keyed on marker_color
	var img := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)                  # exit color
	img.set_pixel(1, 0, Color(0, 0, 1, 1))            # BLUE = BouncyTile type
	img.set_pixel(2, 0, Color(0.5, 0.5, 0, 1))        # marker color
	img.set_pixel(3, 0, Color(0, 0, 0, 0))            # end of command
	var result := LevelLoader.parse_commands(img)
	assert(result.special_tiles.size() == 1, "one special tile")
	var marker := Color(0.5, 0.5, 0, 1)
	assert(marker in result.special_tiles, "marker key present")
	assert(result.special_tiles[marker].type == "bouncy", "type is bouncy")
	print("  _test_parse_commands_bouncy: PASS")

func _test_parse_commands_black_hole() -> void:
	# command: [BLACK, marker, subtract_color] → BlackHoleTile
	var img := Image.create(5, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	img.set_pixel(1, 0, Color(0, 0, 0, 1))            # BLACK = BlackHoleTile
	img.set_pixel(2, 0, Color(0.1, 0, 0, 1))          # marker
	img.set_pixel(3, 0, Color(1, 0, 0, 1))            # subtract = RED
	img.set_pixel(4, 0, Color(0, 0, 0, 0))            # end
	var result := LevelLoader.parse_commands(img)
	var marker := Color(0.1, 0, 0, 1)
	assert(result.special_tiles[marker].type == "black_hole", "type black_hole")
	assert(result.special_tiles[marker].subtract_color == Color.RED, "subtract color")
	print("  _test_parse_commands_black_hole: PASS")

func _test_parse_commands_rainbow() -> void:
	# command: [YELLOW, marker, c1, c2] → RainbowTile with colors [c1, c2]
	var img := Image.create(6, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	img.set_pixel(1, 0, Color(1, 1, 0, 1))            # YELLOW
	img.set_pixel(2, 0, Color(0.2, 0, 0, 1))          # marker
	img.set_pixel(3, 0, Color(1, 0, 0, 1))            # color 1 = RED
	img.set_pixel(4, 0, Color(0, 1, 0, 1))            # color 2 = GREEN
	img.set_pixel(5, 0, Color(0, 0, 0, 0))            # end
	var result := LevelLoader.parse_commands(img)
	var marker := Color(0.2, 0, 0, 1)
	assert(result.special_tiles[marker].type == "rainbow", "type rainbow")
	assert(result.special_tiles[marker].colors.size() == 2, "two colors")
	print("  _test_parse_commands_rainbow: PASS")

func _test_pixel_to_tile_white_is_player() -> void:
	var t := LevelLoader.pixel_to_tile_type(Color.WHITE, {})
	assert(t == "player_spawn", "white → player spawn")
	print("  _test_pixel_to_tile_white_is_player: PASS")

func _test_pixel_to_tile_black_is_exit() -> void:
	var t := LevelLoader.pixel_to_tile_type(Color.BLACK, {})
	assert(t == "exit", "black → exit")
	print("  _test_pixel_to_tile_black_is_exit: PASS")

func _test_pixel_to_tile_color_source() -> void:
	var t := LevelLoader.pixel_to_tile_type(Color(0.5, 0.3, 0.1, 1.0), {})
	assert(t == "color_source", "unknown opaque → color_source")
	print("  _test_pixel_to_tile_color_source: PASS")

func _test_find_path_locs_single() -> void:
	# tile pixel only, no semi-transparent neighbors → path size 1
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	var tile_color := Color(0.5, 0.2, 0.1, 1.0)
	img.set_pixel(1, 2, tile_color)  # y+1 offset: grid (1,1) → image (1, 1+1=2)
	var locs := LevelLoader.find_path_locs(img, Vector2i(1, 1), tile_color)
	assert(locs.size() == 1, "single tile → 1 loc")
	assert(Vector2i(1, 1) in locs, "start included")
	print("  _test_find_path_locs_single: PASS")

func _test_find_path_locs_path() -> void:
	# tile at (1,1) with semi-transparent neighbor at (2,1)
	var img := Image.create(4, 3, false, Image.FORMAT_RGBA8)
	var tile_color := Color(0.5, 0.2, 0.1, 1.0)
	var path_color := Color(0.5, 0.2, 0.1, 0.5)  # same RGB, alpha < 255
	img.set_pixel(1, 2, tile_color)   # grid (1,1)
	img.set_pixel(2, 2, path_color)   # grid (2,1) — path neighbor
	var locs := LevelLoader.find_path_locs(img, Vector2i(1, 1), tile_color)
	assert(locs.size() == 2, "tile + path neighbor = 2 locs")
	assert(Vector2i(1, 1) in locs, "start included")
	assert(Vector2i(2, 1) in locs, "path neighbor included")
	print("  _test_find_path_locs_path: PASS")
