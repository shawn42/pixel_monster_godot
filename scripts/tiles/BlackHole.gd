extends Area2D

var subtract_color: Color = Color.WHITE

func _ready() -> void:
	set_meta("subtract_color", subtract_color)
	set_meta("source_type", "black_hole")

func _process(_delta: float) -> void:
	# ~33% chance per frame: emit particles toward self
	if randf() < 0.33:
		GameEvents.particles_requested.emit(
			subtract_color, self, 1, Vector2(-3, 3), Vector2i(1, 3)
		)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-8, -8, 16, 16), Color(0.12, 0.12, 0.12, 1.0))  # near-black
