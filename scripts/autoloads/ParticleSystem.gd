extends Node

const SCENE_PARTICLE := preload("res://scenes/Particle.tscn")
const POSITIONS_RANGE := 15.0

func _ready() -> void:
	GameEvents.particles_requested.connect(_on_particles_requested)

func _on_particles_requested(
	color: Color,
	target: Node2D,
	intensity: int,
	speed_range: Vector2,
	size_range: Vector2i
) -> void:
	var spawn_parent := get_tree().current_scene
	if not spawn_parent:
		return

	# Split into R/G/B sub-emitters
	var total := color.r + color.g + color.b
	if total <= 0:
		return

	var counts := {
		Color.RED:   roundi(intensity * color.r / total),
		Color.GREEN: roundi(intensity * color.g / total),
		Color.BLUE:  roundi(intensity * color.b / total),
	}

	var spawn_pos: Vector2 = target.position if is_instance_valid(target) else Vector2.ZERO

	for sub_color: Color in counts:
		var count: int = counts[sub_color]
		for _i in count:
			var p: Node2D = SCENE_PARTICLE.instantiate()
			p.position = spawn_pos + Vector2(
				randf_range(-POSITIONS_RANGE, POSITIONS_RANGE),
				randf_range(-POSITIONS_RANGE, POSITIONS_RANGE)
			)
			p.particle_color = sub_color
			p.velocity = Vector2(
				randf_range(speed_range.x, speed_range.y),
				randf_range(speed_range.x, speed_range.y)
			)
			p.particle_size = randi_range(size_range.x, size_range.y)
			p.target = target if is_instance_valid(target) else null
			spawn_parent.add_child(p)
