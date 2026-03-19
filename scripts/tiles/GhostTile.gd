extends Area2D

const ALPHA_MIN := 50.0 / 255.0
const ALPHA_MAX := 1.0
const FADE_SPEED := 0.0001

var tile_color: Color = Color.WHITE
var _alpha: float = ALPHA_MAX
var _fade_dir: float = -1.0  # start fading down

func _ready() -> void:
	set_meta("source_type", "ghost")
	_alpha = ALPHA_MAX
	_update_meta()

func _process(delta: float) -> void:
	var alpha_dt := maxf(delta * FADE_SPEED * 255.0, 1.0 / 255.0)
	_alpha += _fade_dir * alpha_dt
	if _alpha <= ALPHA_MIN:
		_alpha = ALPHA_MIN + (ALPHA_MIN - _alpha)
		_fade_dir = 1.0
	elif _alpha >= ALPHA_MAX:
		_alpha = ALPHA_MAX - (_alpha - ALPHA_MAX)
		_fade_dir = -1.0
	_update_meta()
	queue_redraw()

func _update_meta() -> void:
	var c := tile_color
	c.a = _alpha
	set_meta("tile_color", c)

func _draw() -> void:
	var c := tile_color
	c.a = _alpha
	draw_rect(Rect2(-14, -14, 28, 28), c)
