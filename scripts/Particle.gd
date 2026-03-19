extends Node2D

var particle_color: Color = Color.WHITE
var velocity: Vector2 = Vector2.ZERO
var particle_size: int = 2
var target: Node2D = null
var pull_strength: float = 20.0
var _alpha: float = 1.0

func _process(delta: float) -> void:
	# Attract toward target or drift upward
	if is_instance_valid(target):
		var to_target := target.global_position + Vector2(0, 12) - position
		var dist      := to_target.length()
		if dist > 1:
			velocity += to_target.normalized() * delta * pull_strength
	else:
		velocity.y -= delta * 5.0  # drift upward

	position += velocity * delta * 60.0

	var scalar := delta * 60.0
	_alpha -= 0.033 * scalar  # ~0.5s lifetime at 60fps
	if _alpha <= 0.0:
		queue_free()
		return

	particle_color.a = _alpha
	queue_redraw()

func _draw() -> void:
	var r := Rect2(-particle_size / 2.0, -particle_size / 2.0, particle_size, particle_size)
	# White outline for visibility
	var outline_color := Color(0.7, 0.7, 0.7, particle_color.a * 0.6)
	draw_rect(r.grow(1), outline_color)
	draw_rect(r, particle_color)
