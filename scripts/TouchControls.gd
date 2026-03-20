extends CanvasLayer

var _left_pressed := false
var _right_pressed := false
var _jump_touch_id := -1

const BUTTON_SIZE := 240.0
const BUTTON_MARGIN := 15.0
const BUTTON_Y_OFFSET := 280.0  # distance from bottom
const TOP_BTN_SIZE := 120.0
const TOP_BTN_Y := 30.0  # distance from top
const LEFT_GUTTER  := 550.0
const RIGHT_GUTTER := 550.0

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
		if event.double_tap and _try_teleport(pos):
			return
		elif _is_in_restart_button(pos):
			GameManager.reload_level()
		elif _is_in_skip_button(pos):
			GameManager.skip_level()
		elif _is_in_exit_button(pos) and OS.get_name() != "iOS":
			get_tree().quit()
		elif _is_in_left_target(pos, viewport_size):
			_left_pressed = true
			Input.action_press("move_left")
		elif _is_in_right_target(pos, viewport_size):
			_right_pressed = true
			Input.action_press("move_right")
		elif _is_in_jump_zone(pos, viewport_size):
			_jump_touch_id = event.index
			Input.action_press("jump")
	else:
		# Released
		if _left_pressed and event.index != _jump_touch_id:
			_left_pressed = false
			Input.action_release("move_left")
		if _right_pressed and event.index != _jump_touch_id:
			_right_pressed = false
			Input.action_release("move_right")
		if event.index == _jump_touch_id:
			_jump_touch_id = -1
			Input.action_release("jump")

func _handle_drag(event: InputEventScreenDrag) -> void:
	var pos := event.position
	var viewport_size := get_viewport().get_visible_rect().size

	# If dragging in the button area, update left/right state
	var in_left := _is_in_left_target(pos, viewport_size)
	var in_right := _is_in_right_target(pos, viewport_size)

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

func _is_in_restart_button(pos: Vector2) -> bool:
	var bx := BUTTON_MARGIN
	var by := TOP_BTN_Y
	return pos.x >= bx and pos.x <= bx + TOP_BTN_SIZE and pos.y >= by and pos.y <= by + TOP_BTN_SIZE

func _is_in_skip_button(pos: Vector2) -> bool:
	var bx := BUTTON_MARGIN + TOP_BTN_SIZE + BUTTON_MARGIN
	var by := TOP_BTN_Y
	return pos.x >= bx and pos.x <= bx + TOP_BTN_SIZE and pos.y >= by and pos.y <= by + TOP_BTN_SIZE

func _is_in_exit_button(pos: Vector2) -> bool:
	var bx := BUTTON_MARGIN + (TOP_BTN_SIZE + BUTTON_MARGIN) * 2
	var by := TOP_BTN_Y
	return pos.x >= bx and pos.x <= bx + TOP_BTN_SIZE and pos.y >= by and pos.y <= by + TOP_BTN_SIZE

## Tap targets: split the left gutter below the top buttons into left/right halves
const TOP_BUTTONS_BOTTOM := TOP_BTN_Y + TOP_BTN_SIZE + 15.0  # below top row buttons

func _is_in_left_target(pos: Vector2, _viewport_size: Vector2) -> bool:
	# Left half of left gutter, below top buttons
	return pos.x < LEFT_GUTTER / 2.0 and pos.y > TOP_BUTTONS_BOTTOM

func _is_in_right_target(pos: Vector2, _viewport_size: Vector2) -> bool:
	# Right half of left gutter, below top buttons
	return pos.x >= LEFT_GUTTER / 2.0 and pos.x < LEFT_GUTTER and pos.y > TOP_BUTTONS_BOTTOM

func _is_in_jump_zone(pos: Vector2, viewport_size: Vector2) -> bool:
	# Bottom half of right gutter
	return pos.x > viewport_size.x - RIGHT_GUTTER and pos.y > viewport_size.y / 2.0

func _try_teleport(screen_pos: Vector2) -> bool:
	# Only teleport if tap is in the game area (between gutters)
	var vs := get_viewport().get_visible_rect().size
	if screen_pos.x < LEFT_GUTTER or screen_pos.x > vs.x - RIGHT_GUTTER:
		return false
	var game := get_node_or_null("/root/Game")
	if not game:
		return false
	var level: Node2D = game._level
	if not level or not is_instance_valid(level.player):
		return false
	# Convert screen position to level-local coordinates
	var local_pos := level.get_global_transform().affine_inverse() * screen_pos
	var hw := 12.0  # half player width
	for corner in [Vector2(-hw, -hw), Vector2(hw, -hw), Vector2(-hw, hw), Vector2(hw, hw)]:
		if level.is_blocked(level.world_to_grid(local_pos + corner)):
			return false
	level.player.position = local_pos
	level.player.velocity = Vector2.ZERO
	return true
