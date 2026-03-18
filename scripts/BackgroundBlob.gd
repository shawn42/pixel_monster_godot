extends Node2D

var blob_color: Color = Color(0.5, 0.5, 0.5, 0.2)
var blob_size:  Vector2 = Vector2(200, 200)
var velocity:   Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	position += velocity * (delta / 0.1)  # delta/100 in original (ms-based)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-blob_size.x / 2.0, -blob_size.y / 2.0,
	                blob_size.x, blob_size.y), blob_color)
