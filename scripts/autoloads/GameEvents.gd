extends Node

## Global signal bus — replaces the ECS event-as-component pattern.
## No logic here; just signal declarations.

signal player_died
signal level_complete
signal color_collected(color: Color)
signal sound_requested(path: String)
## speed_range: Vector2(min, max) px/frame; size_range: Vector2i(min, max) px
signal particles_requested(
	color: Color,
	target: Node2D,
	intensity: int,
	speed_range: Vector2,
	size_range: Vector2i
)
