extends Node2D

const WINDOW_SIZE := 1024.0
const MOBILE_LEFT_GUTTER  := 550.0  # left gutter for touch buttons
const MOBILE_RIGHT_GUTTER := 400.0  # right gutter for color inspector

var _level: Node2D = null
var _is_mobile := false
var _timer_ms: float = 0.0
var _hud_timer_label: Label = null
var _hud_best_label:  Label = null
var _color_bars:      Node2D = null

func _ready() -> void:
	GameEvents.level_complete.connect(_on_level_complete)
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.sound_requested.connect(_on_sound_requested)
	_is_mobile = DisplayServer.is_touchscreen_available()

	_hud_timer_label = $HUD/TimerLabel
	_hud_best_label  = $HUD/BestTimeLabel
	_color_bars      = $HUD/ColorBars
	# On mobile, reparent color bars to TouchControls (layer 10) so it draws
	# above the black gutter background, and position in the right gutter
	if _is_mobile:
		var touch := get_node_or_null("/root/Game/TouchControls")
		if touch:
			_color_bars.reparent(touch)
		var right_gutter_center := MOBILE_LEFT_GUTTER + WINDOW_SIZE + MOBILE_RIGHT_GUTTER / 2.0
		_color_bars.position = Vector2(right_gutter_center, WINDOW_SIZE / 2.0 + 60.0)
		_color_bars.scale = Vector2(3.0, 3.0)
		# Center timer labels over the game area, not the full viewport
		var game_center_x := MOBILE_LEFT_GUTTER + WINDOW_SIZE / 2.0
		if _hud_timer_label:
			_hud_timer_label.anchor_left = 0.0
			_hud_timer_label.anchor_right = 0.0
			_hud_timer_label.offset_left = game_center_x - 100.0
			_hud_timer_label.offset_right = game_center_x + 100.0
		if _hud_best_label:
			_hud_best_label.anchor_left = 0.0
			_hud_best_label.anchor_right = 0.0
			_hud_best_label.offset_left = game_center_x - 100.0
			_hud_best_label.offset_right = game_center_x + 100.0

func load_level(level: Node2D) -> void:
	if _level:
		_level.queue_free()
	_level = level
	add_child(level)
	_timer_ms = 0.0
	_update_camera()
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
	_timer_ms += delta * 1000.0
	_update_hud()
	# Update color bar data
	if _color_bars and is_instance_valid(_level.player):
		_color_bars.player_color = _level.player.joy_color
		_color_bars.exit_color   = _level.exit_color
		_color_bars.queue_redraw()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

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
