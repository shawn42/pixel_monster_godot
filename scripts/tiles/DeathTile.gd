extends StaticBody2D

func _ready() -> void:
	set_meta("source_type", "death")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Glitch effect: 50 random colored rects
	for i in 50:
		var rx := randf_range(-16.0, 16.0)  # offset within tile, not tile size
		var ry := randf_range(-16.0, 16.0)
		var rw := randf_range(2.0, 5.0)
		var rh := randf_range(2.0, 5.0)
		var rc := Color(randf_range(0.2, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0),
		                randf_range(0.86, 1.0))
		draw_rect(Rect2(rx, ry, rw, rh), rc)
