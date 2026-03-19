extends StaticBody2D

func _ready() -> void:
	set_meta("source_type", "bouncy")

func _process(_delta: float) -> void:
	# ~20% chance per frame to emit white particles
	if randf() < 0.2:
		GameEvents.particles_requested.emit(
			Color.WHITE, self, 15, Vector2(-2, 2), Vector2i(1, 3), Vector2(-6, -1), Vector2.ZERO
		)
		GameEvents.particles_requested.emit(
			Color.WHITE, self, 15, Vector2(-1, 1), Vector2i(2, 6), Vector2(-3, -0.5), Vector2(0, 8)
		)

func _draw() -> void:
	return
	#draw_rect(Rect2(-16, -16, 32, 32), Color(0.5, 0.5, 0.5, 1.0))  # gray
