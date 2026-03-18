class_name LevelLoader

const TILE_SIZE := 32
const TILE_HALF := TILE_SIZE / 2

# Pixel colors that identify tile command types (top row of PNG)
const CMD_BLACK_HOLE  := Color(0, 0, 0, 1)
const CMD_RAINBOW     := Color(1, 1, 0, 1)
const CMD_SUPER_SRC   := Color(0, 1, 0, 1)  # GREEN = SuperColorSource
const CMD_BOUNCY      := Color(0, 0, 1, 1)
const CMD_DEATH       := Color(1, 0, 0, 1)
const CMD_EMPTY       := Color(0.5, 0.5, 0.5, 1)  # GRAY
const CMD_GHOST       := Color(0, 1, 1, 1)

const PLAYER_COLOR := Color(1, 1, 1, 1)  # WHITE
const EXIT_COLOR   := Color(0, 0, 0, 1)  # BLACK

const PATH_RGB_TOLERANCE := 4.0 / 255.0  # 4 units on 0-255 scale

## Parsed command row result
class ParseResult:
	var exit_color: Color
	var special_tiles: Dictionary  # Color → TileDef

class TileDef:
	var type: String   # "bouncy", "death", "black_hole", "rainbow", "super_src", "empty", "ghost"
	var marker_color: Color
	var display_color: Color
	var subtract_color: Color
	var colors: Array[Color]  # for rainbow

## Parse the top row of a level PNG.
## Returns ParseResult with exit_color and special_tiles dict keyed by marker_color.
static func parse_commands(img: Image) -> ParseResult:
	var result := ParseResult.new()
	result.exit_color = _normalize_color(img.get_pixel(0, 0))
	result.special_tiles = {}

	var command: Array[Color] = []
	for c in range(1, img.get_width()):
		var px: Color = _normalize_color(img.get_pixel(c, 0))
		if px.a > 0:
			command.append(px)
		elif command.size() > 0:
			_process_command(command, result)
			command = []

	return result

static func _process_command(cmd: Array[Color], result: ParseResult) -> void:
	if cmd.size() < 2:
		return
	var type_px: Color = cmd[0]
	var marker: Color  = cmd[1]

	var def := TileDef.new()
	def.marker_color = marker

	if _colors_approx_equal(type_px, CMD_BLACK_HOLE):
		def.type = "black_hole"
		def.subtract_color = cmd[2] if cmd.size() > 2 else Color.WHITE
	elif _colors_approx_equal(type_px, CMD_RAINBOW):
		def.type = "rainbow"
		var cols: Array[Color] = []
		for i in range(2, cmd.size()):
			cols.append(cmd[i])
		def.colors = cols
	elif _colors_approx_equal(type_px, CMD_SUPER_SRC):
		def.type = "super_src"
		def.display_color = cmd[2] if cmd.size() > 2 else Color.WHITE
	elif _colors_approx_equal(type_px, CMD_BOUNCY):
		def.type = "bouncy"
	elif _colors_approx_equal(type_px, CMD_DEATH):
		def.type = "death"
	elif _colors_approx_equal(type_px, CMD_EMPTY):
		def.type = "empty"
	elif _colors_approx_equal(type_px, CMD_GHOST):
		def.type = "ghost"
		def.display_color = cmd[2] if cmd.size() > 2 else Color.WHITE
	else:
		return  # unknown command

	result.special_tiles[marker] = def

## Classify a single opaque pixel from the tile grid.
static func pixel_to_tile_type(px: Color, special_tiles: Dictionary) -> String:
	var norm_px := _normalize_color(px)
	if _colors_approx_equal(norm_px, PLAYER_COLOR):
		return "player_spawn"
	if _colors_approx_equal(norm_px, EXIT_COLOR):
		return "exit"
	for marker: Color in special_tiles:
		if _colors_approx_equal(norm_px, marker):
			return special_tiles[marker].type
	return "color_source"

## Flood-fill from start_loc to find path continuation pixels.
## start_loc is always included. Neighbors included if: alpha > 0, alpha < 1,
## and RGB within PATH_RGB_TOLERANCE of tile_color.
## IMPORTANT: pixel coords = (grid.x, grid.y + 1) to skip command row (y=0).
static func find_path_locs(img: Image, start_loc: Vector2i, tile_color: Color) -> Array[Vector2i]:
	var path_set: Dictionary = {}  # Vector2i → true
	var open_list: Array[Vector2i] = [start_loc]
	path_set[start_loc] = true

	while open_list.size() > 0:
		var active := open_list.pop_back() as Vector2i
		for n_dir: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var neighbor: Vector2i = active + n_dir
			if neighbor in path_set:
				continue
			var nx: int = neighbor.x
			var ny: int = neighbor.y + 1  # +1 to skip command row
			if nx < 0 or ny < 0 or nx >= img.get_width() or ny >= img.get_height():
				continue
			var px: Color = img.get_pixel(nx, ny)
			if px.a > 0 and px.a < 1.0 and _color_close_enough(px, tile_color):
				path_set[neighbor] = true
				open_list.append(neighbor)

	var result: Array[Vector2i] = []
	for k in path_set:
		result.append(k)
	return result

static func _color_close_enough(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < PATH_RGB_TOLERANCE and \
	       absf(a.g - b.g) < PATH_RGB_TOLERANCE and \
	       absf(a.b - b.b) < PATH_RGB_TOLERANCE

static func _colors_approx_equal(a: Color, b: Color) -> bool:
	# Exact match with a small float tolerance
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01

## Normalize a color read from an RGBA8 image to the nearest uint8 step.
## RGBA8 stores colors as 8-bit integers with floor-rounding; this uses
## round-to-nearest so Color keys match both when read from PNG and when
## constructed from float literals that round to the same uint8.
static func _normalize_color(c: Color) -> Color:
	return Color(
		roundf(c.r * 255.0) / 255.0,
		roundf(c.g * 255.0) / 255.0,
		roundf(c.b * 255.0) / 255.0,
		roundf(c.a * 255.0) / 255.0
	)

## Tile scene paths
const SCENE_COLOR_SOURCE  := preload("res://scenes/tiles/ColorSource.tscn")
const SCENE_GHOST         := preload("res://scenes/tiles/GhostTile.tscn")
const SCENE_SUPER_SRC     := preload("res://scenes/tiles/SuperColorSource.tscn")
const SCENE_BOUNCY        := preload("res://scenes/tiles/BouncyTile.tscn")
const SCENE_DEATH         := preload("res://scenes/tiles/DeathTile.tscn")
const SCENE_BLACK_HOLE    := preload("res://scenes/tiles/BlackHole.tscn")
const SCENE_RAINBOW       := preload("res://scenes/tiles/RainbowTile.tscn")
const SCENE_MOVABLE       := preload("res://scenes/tiles/MovableTile.tscn")
const SCENE_EMPTY         := preload("res://scenes/tiles/EmptyTile.tscn")
const SCENE_EXIT          := preload("res://scenes/tiles/Exit.tscn")
const SCENE_PLAYER        := preload("res://scenes/Player.tscn")
const SCENE_LEVEL         := preload("res://scenes/Level.tscn")
const PathWalkerScript    := preload("res://scripts/PathWalker.gd")
const ColorUtilsScript    := preload("res://scripts/autoloads/ColorUtils.gd")

## Load a level from PNG file path (e.g. "res://levels/level1.png").
## Returns a Level node ready to be added to the scene tree.
static func load_level(png_path: String) -> Node2D:
	var img := Image.load_from_file(png_path)
	var parse := parse_commands(img)

	var level: Node2D = SCENE_LEVEL.instantiate()
	level.exit_color  = parse.exit_color
	level.map_width   = img.get_width()
	level.map_height  = img.get_height() - 1  # exclude command row

	var colors: Array[Color] = []

	for col in range(img.get_width()):
		for row in range(img.get_height() - 1):
			var px: Color = img.get_pixel(col, row + 1)
			if px.a < 1.0:
				continue  # transparent or path pixel — skip

			var world_x := float(col * TILE_SIZE + TILE_HALF)
			var world_y := float(row * TILE_SIZE + TILE_HALF)
			var grid_pos := Vector2i(col, row)
			var norm_px := _normalize_color(px)
			var tile_type := pixel_to_tile_type(norm_px, parse.special_tiles)

			match tile_type:
				"player_spawn":
					var p: Node2D = SCENE_PLAYER.instantiate()
					p.position = Vector2(world_x, world_y)
					level.add_child(p)
					level.player = p

				"exit":
					var ex: Node2D = SCENE_EXIT.instantiate()
					ex.position = Vector2(world_x, world_y)
					if ex.get("exit_color") != null:
						ex.set("exit_color", parse.exit_color)
					level.add_child(ex)
					level.exit_node = ex
					level.exit_grid_pos = grid_pos

				"color_source":
					var tile: Node2D = SCENE_COLOR_SOURCE.instantiate()
					tile.position = Vector2(world_x, world_y)
					if tile.get("tile_color") != null:
						tile.set("tile_color", px)
					level.add_child(tile)
					level.color_sources.append(tile)
					colors.append(px)

				"ghost":
					var def: LevelLoader.TileDef = parse.special_tiles.get(norm_px)
					var tile: Node2D = SCENE_GHOST.instantiate()
					tile.position = Vector2(world_x, world_y)
					if tile.get("tile_color") != null:
						tile.set("tile_color", def.display_color if def else px)
					level.add_child(tile)
					level.color_sources.append(tile)

				"super_src":
					var def: LevelLoader.TileDef = parse.special_tiles.get(norm_px)
					var tile: Node2D = SCENE_SUPER_SRC.instantiate()
					tile.position = Vector2(world_x, world_y)
					if tile.get("tile_color") != null:
						tile.set("tile_color", def.display_color if def else px)
					level.add_child(tile)
					level.color_sources.append(tile)

				"bouncy":
					var tile: Node2D = SCENE_BOUNCY.instantiate()
					tile.position = Vector2(world_x, world_y)
					level.add_child(tile)
					level.tile_map[grid_pos] = true
					level.bouncy_tiles.append(tile)

				"death":
					var tile: Node2D = SCENE_DEATH.instantiate()
					tile.position = Vector2(world_x, world_y)
					level.add_child(tile)
					level.death_tiles.append(tile)

				"black_hole":
					var def: LevelLoader.TileDef = parse.special_tiles.get(norm_px)
					var tile: Node2D = SCENE_BLACK_HOLE.instantiate()
					tile.position = Vector2(world_x, world_y)
					if tile.get("subtract_color") != null:
						tile.set("subtract_color", def.subtract_color if def else Color.WHITE)
					level.add_child(tile)
					level.black_holes.append(tile)

				"rainbow":
					var def: LevelLoader.TileDef = parse.special_tiles.get(norm_px)
					var tile: Node2D = SCENE_RAINBOW.instantiate()
					tile.position = Vector2(world_x, world_y)
					if tile.get("colors") != null:
						tile.set("colors", def.colors if def else [Color.WHITE])
					level.add_child(tile)
					level.color_sources.append(tile)

				"empty":
					var tile: Node2D = SCENE_EMPTY.instantiate()
					tile.position = Vector2(world_x, world_y)
					level.add_child(tile)

			# Check for MovableTile path
			if tile_type not in ["player_spawn", "exit", "death", "empty"]:
				var path_locs := find_path_locs(img, grid_pos, px)
				if path_locs.size() > 1:
					var ordered := PathWalkerScript.build_path(path_locs, grid_pos)
					_make_movable(level, col, row, px, ordered, parse, tile_type)

	# Compute average color (from color source pixels only)
	if colors.size() > 0:
		level.average_color = ColorUtilsScript.average_color(colors)
	else:
		level.average_color = parse.exit_color

	return level

## Convert an existing tile into a MovableTile by replacing it with a MovableTile scene.
static func _make_movable(
	level: Node2D,
	col: int, row: int,
	px: Color,
	ordered_path: Array[Vector2i],
	parse: ParseResult,
	tile_type: String
) -> void:
	var world_x := float(col * TILE_SIZE + TILE_HALF)
	var world_y := float(row * TILE_SIZE + TILE_HALF)

	var tile: Node2D = SCENE_MOVABLE.instantiate()
	tile.position = Vector2(world_x, world_y)
	if tile.get("path_nodes") != null:
		tile.set("path_nodes", ordered_path)
	if tile.get("tile_color") != null:
		tile.set("tile_color", px)

	# Inherit color/type data from special tile def if applicable
	var norm_px := _normalize_color(px)
	var def: LevelLoader.TileDef = parse.special_tiles.get(norm_px)
	if def:
		match def.type:
			"color_source", "ghost", "super_src", "rainbow":
				if tile.get("source_type") != null:
					tile.set("source_type", def.type)
				if not def.display_color.is_equal_approx(Color()):
					if tile.get("tile_color") != null:
						tile.set("tile_color", def.display_color)
				elif def.colors.size() > 0:
					if tile.get("tile_color") != null:
						tile.set("tile_color", def.colors[0])

	level.add_child(tile)
	level.moving_tiles.append(tile)
