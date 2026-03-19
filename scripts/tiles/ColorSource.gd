extends StaticBody2D

var tile_color: Color = Color.WHITE

func _ready() -> void:
	set_meta("tile_color", tile_color)
	set_meta("source_type", "color_source")

func _draw() -> void:
	draw_rect(Rect2(-16, -16, 32, 32), tile_color)
