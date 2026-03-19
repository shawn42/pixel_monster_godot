extends Area2D

var exit_color: Color = Color.WHITE
var _is_open: bool = false
var _outer_size: float = 28.0
var _inner_size: float = 16.0
var _y_offset: float = 0.0

func _ready() -> void:
	set_meta("source_type", "exit")
	z_index = 10

func set_open(open: bool) -> void:
	if open == _is_open:
		return
	_is_open = open
	if open:
		_outer_size = 44.0
		_inner_size = 32.0
		_y_offset = -8.0  # grow upward, keep bottom aligned
	else:
		_outer_size = 28.0
		_inner_size = 16.0
		_y_offset = 0.0
	queue_redraw()

func _draw() -> void:
	var oh := _outer_size / 2.0
	var ih := _inner_size / 2.0
	draw_rect(Rect2(-oh, -oh + _y_offset, _outer_size, _outer_size), exit_color)
	draw_rect(Rect2(-ih, -ih + _y_offset, _inner_size, _inner_size), Color.BLACK)
