extends CanvasLayer

var _left_pressed := false
var _right_pressed := false
var _jump_touch_id := -1

const BUTTON_SIZE := 120.0
const BUTTON_MARGIN := 30.0
const BUTTON_Y_OFFSET := 160.0  # distance from bottom

func _ready() -> void:
	# Only show on touchscreen devices
	if not DisplayServer.is_touchscreen_available():
		queue_free()
		return
	layer = 10

func _draw() -> void:
	pass  # Drawing handled by child Control

func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var pos := event.position
	var viewport_size := get_viewport().get_visible_rect().size

	if event.pressed:
		if _is_in_left_button(pos, viewport_size):
			_left_pressed = true
			Input.action_press("move_left")
		elif _is_in_right_button(pos, viewport_size):
			_right_pressed = true
			Input.action_press("move_right")
		else:
			# Tap anywhere else = jump
			_jump_touch_id = event.index
			Input.action_press("jump")
	else:
		# Released
		if _is_in_left_button(pos, viewport_size) or (event.index != _jump_touch_id and _left_pressed):
			_left_pressed = false
			Input.action_release("move_left")
		if _is_in_right_button(pos, viewport_size) or (event.index != _jump_touch_id and _right_pressed):
			_right_pressed = false
			Input.action_release("move_right")
		if event.index == _jump_touch_id:
			_jump_touch_id = -1
			Input.action_release("jump")

func _handle_drag(event: InputEventScreenDrag) -> void:
	var pos := event.position
	var viewport_size := get_viewport().get_visible_rect().size

	# If dragging in the button area, update left/right state
	var in_left := _is_in_left_button(pos, viewport_size)
	var in_right := _is_in_right_button(pos, viewport_size)

	if event.index != _jump_touch_id:
		if in_left and not _left_pressed:
			_left_pressed = true
			_right_pressed = false
			Input.action_press("move_left")
			Input.action_release("move_right")
		elif in_right and not _right_pressed:
			_right_pressed = true
			_left_pressed = false
			Input.action_press("move_right")
			Input.action_release("move_left")
		elif not in_left and not in_right:
			if _left_pressed:
				_left_pressed = false
				Input.action_release("move_left")
			if _right_pressed:
				_right_pressed = false
				Input.action_release("move_right")

func _is_in_left_button(pos: Vector2, viewport_size: Vector2) -> bool:
	var bx := BUTTON_MARGIN
	var by := viewport_size.y - BUTTON_Y_OFFSET
	return pos.x >= bx and pos.x <= bx + BUTTON_SIZE and pos.y >= by and pos.y <= by + BUTTON_SIZE

func _is_in_right_button(pos: Vector2, viewport_size: Vector2) -> bool:
	var bx := BUTTON_MARGIN + BUTTON_SIZE + BUTTON_MARGIN
	var by := viewport_size.y - BUTTON_Y_OFFSET
	return pos.x >= bx and pos.x <= bx + BUTTON_SIZE and pos.y >= by and pos.y <= by + BUTTON_SIZE
