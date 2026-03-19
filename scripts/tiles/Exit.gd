extends Area2D

var exit_color: Color = Color.WHITE
var _is_open: bool = false
var _outer_size: float = 28.0

func _ready() -> void:
	set_meta("source_type", "exit")

func set_open(open: bool) -> void:
	if open == _is_open:
		return
	_is_open = open
	_outer_size = 44.0 if open else 28.0  # +16 when open
	queue_redraw()

func _draw() -> void:
	var half := _outer_size / 2.0
	draw_rect(Rect2(-half, -half, _outer_size, _outer_size), exit_color)
	draw_rect(Rect2(-8, -8, 16, 16), Color.BLACK)
