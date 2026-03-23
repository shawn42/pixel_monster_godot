extends Node2D

const WINDOW_SIZE := 1024.0
const MOBILE_LEFT_GUTTER  := 550.0  # left gutter for touch buttons
const MOBILE_RIGHT_GUTTER := 550.0  # right gutter for jump button + color inspector

var _level: Node2D = null
var _is_mobile := false
var _timer_ms: float = 0.0
var _timer_started := false
var _hud_level_label: Label = null
var _hud_timer_label: Label = null
var _hud_best_label:  Label = null
var _color_bars:      Node2D = null
var _timer_bg:        Node2D = null

func _ready() -> void:
	GameEvents.level_complete.connect(_on_level_complete)
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.sound_requested.connect(_on_sound_requested)
	_is_mobile = DisplayServer.is_touchscreen_available()

	_hud_level_label = $HUD/LevelNameLabel
	_hud_timer_label = $HUD/TimerLabel
	_hud_best_label  = $HUD/BestTimeLabel
	_color_bars      = $HUD/ColorBars
	# Add darkened background behind timer labels
	_timer_bg = _TimerBackground.new()
	$HUD.add_child(_timer_bg)
	$HUD.move_child(_timer_bg, 0)  # behind the labels
	# On mobile, reparent color bars to TouchControls (layer 10) so it draws
	# above the black gutter background, and position in the right gutter
	if _is_mobile:
		var touch := get_node_or_null("/root/Game/TouchControls")
		if touch:
			_color_bars.reparent(touch)
		var right_gutter_center := MOBILE_LEFT_GUTTER + WINDOW_SIZE + MOBILE_RIGHT_GUTTER / 2.0
		_color_bars.position = Vector2(right_gutter_center, WINDOW_SIZE / 4.0)
		_color_bars.scale = Vector2(3.0, 3.0)
		# Center timer labels and background over the game area
		var game_center_x := MOBILE_LEFT_GUTTER + WINDOW_SIZE / 2.0
		if _timer_bg:
			_timer_bg.bg_center_x = game_center_x
		for lbl in [_hud_level_label, _hud_timer_label, _hud_best_label]:
			if lbl:
				lbl.anchor_left = 0.0
				lbl.anchor_right = 0.0
				lbl.offset_left = game_center_x - 150.0
				lbl.offset_right = game_center_x + 150.0

	# Load first level when Game scene starts
	GameManager.call_deferred("load_level", 0)

func load_level(level: Node2D) -> void:
	# Clear any lingering particles from previous level/death
	for p in get_tree().get_nodes_in_group("particles"):
		p.queue_free()
	if _level:
		_level.queue_free()
	_level = level
	add_child(level)
	_timer_ms = 0.0
	_timer_started = false
	_update_camera()
	# Update level name label
	if _hud_level_label:
		_hud_level_label.text = "%d: %s" % [GameManager.current_level_index + 1, GameManager.level_name(GameManager.current_level_index)]
	# Update best time label
	if _hud_best_label:
		var best_ms: Variant = GameManager.best_ms(GameManager.current_level_index)
		_hud_best_label.text = "(%s)" % ("%.1f" % (best_ms / 1000.0) if best_ms != null else "?")

func _update_camera() -> void:
	if not _level:
		return
	var gutter := MOBILE_LEFT_GUTTER if _is_mobile else 0.0
	var lw := float(_level.map_width  * 32)
	var lh := float(_level.map_height * 32)
	var scale_x := WINDOW_SIZE / lw
	var scale_y  := WINDOW_SIZE / lh
	if lw > WINDOW_SIZE or lh > WINDOW_SIZE:
		# Autofit: scale to fit
		var s := minf(scale_x, scale_y)
		_level.scale = Vector2(s, s)
		_level.position = Vector2(gutter, 0.0)
	else:
		# Small level: center in game area (right of gutter)
		_level.scale = Vector2.ONE
		_level.position = Vector2(gutter + WINDOW_SIZE / 2.0 - lw / 2.0,
								  WINDOW_SIZE / 2.0 - lh / 2.0)

func _process(delta: float) -> void:
	if not _level:
		return
	if not _timer_started:
		for action in ["move_left", "move_right", "jump", "reset"]:
			if Input.is_action_just_pressed(action):
				_timer_started = true
				break
	if _timer_started:
		_timer_ms += delta * 1000.0
	_update_hud()
	# Update color bar data
	if _color_bars and is_instance_valid(_level.player):
		_color_bars.player_color = _level.player.joy_color
		_color_bars.exit_color   = _level.exit_color
		_color_bars.queue_redraw()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	# Skip/prev must work even during death delay (player physics is paused)
	if Input.is_action_just_pressed("skip_level") and not Input.is_key_pressed(KEY_SHIFT):
		GameManager.skip_level()
	if Input.is_action_just_pressed("prev_level"):
		GameManager.prev_level()

func _update_hud() -> void:
	if _hud_timer_label:
		_hud_timer_label.text = "%.1f" % (_timer_ms / 1000.0)
	if _color_bars:
		_color_bars.queue_redraw()

func _on_level_complete() -> void:
	GameManager.complete_level(_timer_ms)

func _on_player_died() -> void:
	GameManager.reload_level()

func _on_sound_requested(path: String) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.autoplay = true
	add_child(player)
	player.finished.connect(player.queue_free)

## Draws the darkened background + white border behind the timer/best labels.
class _TimerBackground extends Node2D:
	var bg_center_x: float = 512.0  # overridden on mobile

	func _draw() -> void:
		var w := 240.0
		var h := 160.0
		var x := bg_center_x - w / 2.0
		var y := 10.0
		# Dark background
		draw_rect(Rect2(x, y, w, h), Color(0, 0, 0, 0.25))
		# White border
		draw_rect(Rect2(x, y, w, h), Color.WHITE, false, 1.0)

	func _process(_delta: float) -> void:
		queue_redraw()
