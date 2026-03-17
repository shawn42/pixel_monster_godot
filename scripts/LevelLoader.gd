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
