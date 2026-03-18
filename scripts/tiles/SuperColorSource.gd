extends Area2D

var tile_color: Color = Color.WHITE
var _border_size: float = 16.0

func _ready() -> void:
	set_meta("tile_color", tile_color)
	set_meta("source_type", "super_src")

func _process(_delta: float) -> void:
	var change := randf_range(-2.0, 3.0)
	_border_size = clampf(_border_size + change, 14.0, 18.0)
	queue_redraw()

func _draw() -> void:
	# Outer pulsing border rect
	var half_b := _border_size / 2.0
	draw_rect(Rect2(-half_b, -half_b, _border_size, _border_size), tile_color)
	# Inner solid rect (16x16)
	draw_rect(Rect2(-8, -8, 16, 16), tile_color)
