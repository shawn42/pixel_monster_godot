extends Node2D

const SCENE_PLAYER      := preload("res://scenes/Player.tscn")
const SCENE_COLOR_SOURCE := preload("res://scenes/tiles/ColorSource.tscn")
const SCENE_LEVEL        := preload("res://scenes/Level.tscn")
const SCENE_BOUNCY       := preload("res://scenes/tiles/BouncyTile.tscn")

const TILE_SIZE := 32
const TILE_HALF := TILE_SIZE / 2
const TILE_COUNT := 20
const FLOOR_Y := 28  # grid row for floor
const TILES_Y := 27  # grid row for color tiles (one above floor)
const TILES_START_X := 6  # grid col where tiles start (centered in 32-wide area)
const SPAWN_Y := 5        # grid row behind the logo (logo is ~y180-280)

var _level: Level = null
var _player: Node2D = null
var _color_tiles: Array[Node2D] = []
var _floor_visuals: Array[ColorRect] = []
var _ai_dir := 1  # 1 = right, -1 = left
var _ai_jump_timer := 0.0
var _recharge_timer := -1.0
var _start_label: Label = null
var _pulse_time := 0.0

const MUSIC_FILES := [
	"res://music/Ozzed---8-bit-Run-n-Pun---01-Introjiuce.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---02-Failien-Funk.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---03-Stroll-n-Roll.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---04-Shell-Shock-Shake.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---05-Im-a-Fighter.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---06-Going-Down-Tune.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---07-Cloud-Crash.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---08-Filaments-and-Voids.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---09-Bonus-Rage.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---10-Its-not-My-Ship.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---11-Perihelium.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---12-Shingle-Tingle.mp3",
	"res://music/Ozzed---8-bit-Run-n-Pun---13-Just-a-Minuet.mp3",
]

func _ready() -> void:
	_build_demo_level()
	_build_ui()
	# Play random background music
	var music := AudioStreamPlayer.new()
	music.stream = load(MUSIC_FILES.pick_random())
	music.volume_db = linear_to_db(0.1)
	music.autoplay = true
	add_child(music)

func _process(delta: float) -> void:
	# Pulse the start label
	_pulse_time += delta
	if _start_label:
		_start_label.modulate.a = 0.5 + 0.5 * sin(_pulse_time * 3.0)

	# Check for start input
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		_start_game()
		return

	# AI player control — respawn if dead or fallen off
	if _player and is_instance_valid(_player):
		if _player.get("_dead") or _player.position.y > 1100:
			_respawn_player()
		else:
			_run_ai(delta)

	# Recharge tiles after all collected
	if _recharge_timer >= 0:
		_recharge_timer -= delta
		if _recharge_timer <= 0:
			_recharge_tiles()
			_recharge_timer = -1.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_start_game()

func _start_game() -> void:
	# Release all AI-injected inputs before switching scenes
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _run_ai(delta: float) -> void:
	# Walk left/right
	var right_edge := float(TILES_START_X + TILE_COUNT) * TILE_SIZE
	var left_edge := float(TILES_START_X) * TILE_SIZE

	# Usually turn at edges, but ~20% chance to keep going and fall off
	if _player.position.x >= right_edge - TILE_HALF and _ai_dir > 0:
		if randf() < 0.5:
			_ai_dir = -1
	elif _player.position.x <= left_edge + TILE_HALF and _ai_dir < 0:
		if randf() < 0.5:
			_ai_dir = 1

	if _ai_dir > 0:
		Input.action_press("move_right")
		Input.action_release("move_left")
	else:
		Input.action_press("move_left")
		Input.action_release("move_right")

	# Occasional jump
	_ai_jump_timer -= delta
	if _ai_jump_timer <= 0:
		Input.action_press("jump")
		call_deferred("_release_jump")
		_ai_jump_timer = randf_range(2.0, 5.0)

	# Check if all tiles collected
	if _recharge_timer < 0 and _level.color_sources.is_empty():
		_recharge_timer = 1.0

func _release_jump() -> void:
	Input.action_release("jump")

func _spawn_player() -> void:
	_player.position = Vector2(
		(TILES_START_X + TILE_COUNT / 2) * TILE_SIZE + TILE_HALF,
		SPAWN_Y * TILE_SIZE + TILE_HALF
	)
	_player.velocity = Vector2.ZERO

func _respawn_player() -> void:
	# Replace the dead player with a fresh one
	if _player and is_instance_valid(_player):
		_player.queue_free()
	_player = SCENE_PLAYER.instantiate()
	_spawn_player()
	_level.add_child(_player)
	_level.player = _player
	_player.level = _level

func _build_demo_level() -> void:
	_level = SCENE_LEVEL.instantiate()
	_level.map_width = 32
	_level.map_height = 32
	_level.exit_color = Color.BLACK
	_level.average_color = Color(0.5, 0.5, 0.5)
	_level.exit_grid_pos = Vector2i(-1, -1)  # no exit
	add_child(_level)
	# Offset by left gutter on mobile
	if DisplayServer.is_touchscreen_available():
		_level.position.x = 550.0

	# Floor tiles (random color static bodies)
	var floor_color := Color(randf_range(0.2, 0.6), randf_range(0.2, 0.6), randf_range(0.2, 0.6))
	for x in range(TILES_START_X, TILES_START_X + TILE_COUNT):
		var floor_tile := StaticBody2D.new()
		var shape_owner := floor_tile.create_shape_owner(floor_tile)
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		floor_tile.shape_owner_add_shape(shape_owner, rect)
		var world_x := x * TILE_SIZE + TILE_HALF
		var world_y := FLOOR_Y * TILE_SIZE + TILE_HALF
		floor_tile.position = Vector2(world_x, world_y)
		_level.tile_map[Vector2i(x, FLOOR_Y)] = true
		var vis := ColorRect.new()
		vis.color = floor_color
		vis.size = Vector2(TILE_SIZE, TILE_SIZE)
		vis.position = Vector2(-TILE_HALF, -TILE_HALF)
		floor_tile.add_child(vis)
		_level.add_child(floor_tile)
		_floor_visuals.append(vis)

	# Bouncy tiles on the color tile row (gives random super jumps)
	for bx in [TILES_START_X + TILE_COUNT / 3, TILES_START_X + TILE_COUNT * 2 / 3]:
		var bouncy: Node2D = SCENE_BOUNCY.instantiate()
		bouncy.position = Vector2(bx * TILE_SIZE + TILE_HALF, TILES_Y * TILE_SIZE + TILE_HALF)
		_level.add_child(bouncy)
		_level.bouncy_tiles.append(bouncy)

	# Color tiles
	_spawn_color_tiles()

	# Player — spawns behind the logo, falls down
	_player = SCENE_PLAYER.instantiate()
	_spawn_player()
	_level.add_child(_player)
	_level.player = _player
	_player.level = _level

func _spawn_color_tiles() -> void:
	for x in range(TILES_START_X, TILES_START_X + TILE_COUNT):
		var tile: Node2D = SCENE_COLOR_SOURCE.instantiate()
		var color := Color(randf_range(0.2, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0))
		tile.tile_color = color
		tile.position = Vector2(x * TILE_SIZE + TILE_HALF, TILES_Y * TILE_SIZE + TILE_HALF)
		_level.add_child(tile)
		_level.color_sources.append(tile)
		_color_tiles.append(tile)

func _recharge_tiles() -> void:
	# Remove any leftover tiles
	for tile in _color_tiles:
		if is_instance_valid(tile):
			_level.color_sources.erase(tile)
			tile.queue_free()
	_color_tiles.clear()
	# Reset player color
	if _player and is_instance_valid(_player):
		_player.joy_color = Color.BLACK
	# Randomize floor color
	var floor_color := Color(randf_range(0.2, 0.6), randf_range(0.2, 0.6), randf_range(0.2, 0.6))
	for vis in _floor_visuals:
		if is_instance_valid(vis):
			vis.color = floor_color
	# Spawn fresh tiles
	_spawn_color_tiles()

func _build_ui() -> void:
	var hud := CanvasLayer.new()
	hud.name = "MenuHUD"
	add_child(hud)

	var is_mobile := DisplayServer.is_touchscreen_available()
	var center_x := 512.0
	if is_mobile:
		center_x = 550.0 + 512.0  # left gutter + half game area

	# Logo image
	var logo := TextureRect.new()
	logo.texture = preload("res://icon.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.anchor_left = 0.0
	logo.anchor_right = 0.0
	logo.offset_left = center_x - 50.0
	logo.offset_top = 180.0
	logo.offset_right = center_x + 50.0
	logo.offset_bottom = 280.0
	hud.add_child(logo)

	# Title — RichTextLabel with rainbow BBCode
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	var rainbow_text := _make_rainbow_title("Pixel Monster")
	title.text = "[center][font_size=72][b]" + rainbow_text + "[/b][/font_size][/center]"
	title.anchor_left = 0.0
	title.anchor_right = 0.0
	title.offset_left = center_x - 300.0
	title.offset_top = 300.0
	title.offset_right = center_x + 300.0
	title.offset_bottom = 400.0
	hud.add_child(title)

	# Start prompt
	_start_label = Label.new()
	_start_label.text = "Tap to Start" if is_mobile else "Press Enter to Start"
	_start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_label.add_theme_font_size_override("font_size", 32)
	_start_label.anchor_left = 0.0
	_start_label.anchor_right = 0.0
	_start_label.offset_left = center_x - 200.0
	_start_label.offset_top = 420.0
	_start_label.offset_right = center_x + 200.0
	_start_label.offset_bottom = 470.0
	hud.add_child(_start_label)

func _make_rainbow_title(text: String) -> String:
	var colors := [
		"#ff0000", "#ff7700", "#ffff00", "#00ff00",
		"#0077ff", "#0000ff", "#8800ff",
	]
	var result := ""
	var ci := 0
	for ch in text:
		if ch == " ":
			result += " "
		else:
			result += "[color=%s]%s[/color]" % [colors[ci % colors.size()], ch]
			ci += 1
	return result
