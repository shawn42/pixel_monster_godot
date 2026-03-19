extends StaticBody2D

const SCENE_PARTICLE := preload("res://scenes/Particle.tscn")
const SPAWN_RADIUS   := 28.0
const TANGENT_SPEED  := 1
const PULL_STRENGTH  := 8.0

var subtract_color: Color = Color.WHITE

func _ready() -> void:
	set_meta("subtract_color", subtract_color)
	set_meta("source_type", "black_hole")

func _process(_delta: float) -> void:
	if randf() < 0.15:
		_spawn_spiral_particle()
	queue_redraw()

func _spawn_spiral_particle() -> void:
	var spawn_parent := get_tree().current_scene
	if not spawn_parent:
		return
	var angle := randf() * TAU
	var p: Node2D = SCENE_PARTICLE.instantiate()
	p.position = global_position + Vector2(cos(angle), sin(angle)) * SPAWN_RADIUS
	# Tangential velocity (clockwise)
	p.velocity = Vector2(sin(angle), -cos(angle)) * randf_range(TANGENT_SPEED * 0.5, TANGENT_SPEED * 1.5)
	p.particle_color = subtract_color
	p.particle_size = randi_range(5, 12)
	p.target = self
	p.pull_strength = randf_range(PULL_STRENGTH * 0.7, PULL_STRENGTH * 1.3)
	spawn_parent.add_child(p)

func _draw() -> void:
	draw_rect(Rect2(-16, -16, 32, 32), Color(0.12, 0.12, 0.12, 1.0))  # near-black
