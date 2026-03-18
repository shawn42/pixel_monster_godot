extends Node2D

var particle_color: Color = Color.WHITE
var velocity: Vector2 = Vector2.ZERO
var particle_size: int = 2
var target: Node2D = null
var _alpha: float = 1.0

func _process(delta: float) -> void:
	# Attract toward target or drift upward
	if is_instance_valid(target):
		var to_target := target.position - position
		var dist      := to_target.length()
		if dist > 1:
			velocity += to_target.normalized() * delta * 10.0
	else:
		velocity.y -= delta * 5.0  # drift upward

	position += velocity * delta * 60.0

	var scalar := delta * 60.0
	_alpha -= 20.0 * scalar / 255.0
	if _alpha <= 0.0:
		queue_free()
		return

	particle_color.a = _alpha
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-particle_size / 2.0, -particle_size / 2.0,
	                particle_size, particle_size), particle_color)
