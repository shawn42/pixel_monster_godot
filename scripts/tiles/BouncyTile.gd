extends StaticBody2D

func _ready() -> void:
	set_meta("source_type", "bouncy")

func _process(_delta: float) -> void:
	# ~20% chance per frame to emit white particles
	if randf() < 0.2:
		GameEvents.particles_requested.emit(
			Color.WHITE, self, 15, Vector2(-3, 3), Vector2i(1, 3)
		)

func _draw() -> void:
	draw_rect(Rect2(-8, -8, 16, 16), Color(0.5, 0.5, 0.5, 1.0))  # gray
