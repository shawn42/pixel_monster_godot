extends Area2D

var tile_color: Color = Color.WHITE

func _ready() -> void:
	set_meta("tile_color", tile_color)
	set_meta("source_type", "ghost")

func _draw() -> void:
	var c := tile_color
	c.a = 0.5
	draw_rect(Rect2(-7, -7, 14, 14), c)
