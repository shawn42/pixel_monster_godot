extends Node2D

const WINDOW_SIZE := 1024.0

var _level: Node2D = null
var _timer_ms: float = 0.0
var _hud_timer_label: Label = null
var _hud_best_label:  Label = null
var _color_bars:      Node2D = null

func _ready() -> void:
	GameEvents.level_complete.connect(_on_level_complete)
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.sound_requested.connect(_on_sound_requested)

	_hud_timer_label = $HUD/TimerLabel
	_hud_best_label  = $HUD/BestTimeLabel
	_color_bars      = $HUD/ColorBars

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
	var lw := float(_level.map_width  * 32)
	var lh := float(_level.map_height * 32)
	var scale_x := WINDOW_SIZE / lw
	var scale_y  := WINDOW_SIZE / lh
	if lw > WINDOW_SIZE or lh > WINDOW_SIZE:
		# Autofit: scale to fit
		var s := minf(scale_x, scale_y)
		_level.scale = Vector2(s, s)
		_level.position = Vector2.ZERO
	else:
		# Small level: stationary center at (512, 512)
		_level.scale = Vector2.ONE
		_level.position = Vector2(WINDOW_SIZE / 2.0 - lw / 2.0,
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
