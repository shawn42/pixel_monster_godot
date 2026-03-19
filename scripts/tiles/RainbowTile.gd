extends StaticBody2D

var colors: Array[Color] = [Color.WHITE]
var _color_index: int = 0

func _ready() -> void:
	if colors.is_empty():
		colors = [Color.WHITE]
	_update_color()
	set_meta("source_type", "rainbow")

	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = false
	timer.timeout.connect(_on_timer)
	add_child(timer)
	timer.start()

func _on_timer() -> void:
	_color_index = (_color_index + 1) % colors.size()
	_update_color()
	queue_redraw()

func _update_color() -> void:
	set_meta("tile_color", colors[_color_index])

func _draw() -> void:
	draw_rect(Rect2(-16, -16, 32, 32), colors[_color_index])
