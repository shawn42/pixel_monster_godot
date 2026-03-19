extends CharacterBody2D
class_name Player

const TILE_SIZE   := 32               # must match LevelLoader/Level
const TILE_HALF   := TILE_SIZE / 2    # 16 — half-extent of one tile
const PLAYER_HALF := TILE_HALF - 2   # 14 — player slightly smaller than tile

const GRAVITY        := 45.0          # 0.75 px/frame × 60fps → px/s per frame
const MAX_VEL        := 900.0         # 15 px/frame × 60fps
const JUMP_FORCE     := -930.0
const SUPER_JUMP     := -1550.0
const JUMP_FORGIVE   := 0.100         # 100ms
const RUN_FORGIVE    := 0.020         # 20ms
const LATERAL_ACCEL  := 60000.0 / 17.0  # 1000/17 × 60fps → px/s²

var joy_color: Color = Color.BLACK
var level: Level = null  # set by LevelLoader after spawning

# Jump state
var _last_grounded_at := -1.0
var _last_jump_force  := 0.0
var _next_jump_boosted := false  # set by BouncyTile detection

# Squish state (independent X and Y)
var _squish_y_at     := -1.0
var _squish_y_height := 0.0
var _squish_y_dir    := 0
var _squish_y_amount := 0.0

var _squish_x_at     := -1.0
var _squish_x_width  := 0.0
var _squish_x_dir    := 0
var _squish_x_amount := 0.0

const SQUISH_DURATION := 0.150
const SQUISH_PEAK     := SQUISH_DURATION / 4.0
const SQUISH_Y_MAX    := 11.0
const SQUISH_X_MAX    := 18.0

var _time := 0.0
var _on_moving_tile := false
var _moving_tile_vel := Vector2.ZERO

func _ready() -> void:
	# Layer 2: not on layer 1 (walls) so moving tiles (mask=1) can't be blocked by us.
	# Mask 5 = layer 1 (walls) + layer 3/bitmask4 (moving tiles) — player can stand on both.
	collision_layer = 2
	collision_mask  = 5

func _physics_process(delta: float) -> void:
	_time += delta
	_on_moving_tile = false

	# --- Gravity ---
	if not is_on_floor():
		if _time - _last_grounded_at > RUN_FORGIVE:
			velocity.y = minf(velocity.y + GRAVITY, MAX_VEL)
	else:
		_last_grounded_at = _time
		velocity.y = 0.0
	_check_bouncy_below()

	# --- Check moving tile below ---
	if level:
		_check_moving_tile_below(delta)

	# --- Lateral movement ---
	var on_ground_not_moving := is_on_floor() and not _on_moving_tile
	var accel := LATERAL_ACCEL * delta
	if not on_ground_not_moving:
		accel *= 2.0  # Ruby: lateral_speed /= 0.5 (i.e. ×2) when not on solid ground

	var old_vx := velocity.x
	if Input.is_action_pressed("move_left"):
		velocity.x -= accel
		if old_vx >= 0:
			_trigger_squish_x(SQUISH_X_MAX * 0.6, -1)
	elif Input.is_action_pressed("move_right"):
		velocity.x += accel
		if old_vx <= 0:
			_trigger_squish_x(SQUISH_X_MAX * 0.6, 1)

	velocity.x = clampf(velocity.x, -MAX_VEL, MAX_VEL)

	# --- Friction ---
	if _on_moving_tile:
		# Strong friction relative to tile velocity — player drifts toward tile speed
		var rel_vx := velocity.x - _moving_tile_vel.x
		velocity.x = _moving_tile_vel.x + rel_vx * 0.7
	elif is_on_floor():
		velocity.x *= 0.9
	else:
		velocity.x *= 0.76

	# --- Jump ---
	var can_jump := (_time - _last_grounded_at) < JUMP_FORGIVE
	if Input.is_action_just_pressed("jump") and can_jump:
		var force := SUPER_JUMP if _next_jump_boosted else JUMP_FORCE
		_last_jump_force = force
		_next_jump_boosted = false
		_last_grounded_at = -1.0
		velocity.y = force
		_trigger_squish_y(-velocity.y / MAX_VEL * SQUISH_Y_MAX, 1)
		GameEvents.sound_requested.emit("res://sounds/" + ["jump1.wav","jump2.wav"].pick_random())

	elif Input.is_action_just_released("jump"):
		# Variable jump height: cap upward velocity on early release
		var cap := _last_jump_force * (0.6 if _last_jump_force == SUPER_JUMP else 0.5)
		if velocity.y < cap:
			velocity.y = cap

	# --- Horizontal wrap ---
	if level:
		var right_edge := float(level.map_width * 32)
		position.x = fmod(position.x + right_edge, right_edge)

	# --- Collision + squish ---
	var old_vy := velocity.y
	move_and_slide()

	# Y-hit (landing or ceiling)
	if is_on_floor() and old_vy > 0:
		_trigger_squish_y(maxf(old_vy, 360.0) / MAX_VEL * SQUISH_Y_MAX, 1)
		GameEvents.sound_requested.emit("res://sounds/collect.wav")
	elif velocity.y == 0 and old_vy < 0:
		_trigger_squish_y(maxf(-old_vy, 360.0) / MAX_VEL * SQUISH_Y_MAX, -1)

	# X-hit (wall)
	if velocity.x == 0 and absf(old_vx) > 0 and not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		_trigger_squish_x(maxf(absf(old_vx), 360.0) / MAX_VEL * SQUISH_X_MAX, sign(old_vx) as int)

	# --- Fall off map ---
	if position.y > 1100:
		_die()

	# --- Tile interactions ---
	if level:
		_check_tile_interactions()

	# --- Level actions ---
	if Input.is_action_just_pressed("skip_level") and not Input.is_key_pressed(KEY_SHIFT):
		GameEvents.level_complete.emit()  # skip = immediate next level
	if Input.is_action_just_pressed("prev_level"):
		GameManager.prev_level()
	if Input.is_action_just_pressed("reset"):
		_die()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.shift_pressed:
		if not level:
			return
		var target := get_global_mouse_position()
		var hw := float(PLAYER_HALF)
		for corner in [Vector2(-hw, -hw), Vector2(hw, -hw), Vector2(-hw, hw), Vector2(hw, hw)]:
			if level.is_blocked(level.world_to_grid(target + corner)):
				return
		position = target
		velocity = Vector2.ZERO

func _process(delta: float) -> void:
	_update_squish(delta)
	queue_redraw()

func _check_moving_tile_below(delta: float) -> void:
	return
	for tile: Node2D in level.moving_tiles:
		if not is_instance_valid(tile):
			continue
		var tp: Vector2 = tile.position
		var pw: Vector2 = position
		var x_dist := absf(pw.x - tp.x)
		var y_dist := absf((pw.y + PLAYER_HALF) - (tp.y - TILE_HALF))
		var x_ok := x_dist <= (PLAYER_HALF + TILE_HALF)
		var y_ok := y_dist <= 4

		if x_ok and y_ok:
			_on_moving_tile = true
			var tv: Vector2 = tile.get_meta("velocity", Vector2.ZERO)
			_moving_tile_vel = tv
			velocity.y = tv.y
			break

func _check_bouncy_below() -> void:
	if not level or not is_on_floor():
		_next_jump_boosted = false
		return
	for tile: Node2D in level.bouncy_tiles:
		if not is_instance_valid(tile):
			continue
		var tp := tile.position
		if absf(position.x - tp.x) <= (PLAYER_HALF + TILE_HALF) and absf((position.y + PLAYER_HALF) - (tp.y - TILE_HALF)) <= 2:
			_next_jump_boosted = true
			return
	_next_jump_boosted = false

func _check_tile_interactions() -> void:
	const MIN_DIST_SQ := 80.0 * 80.0
	var ph := Vector2(float(PLAYER_HALF), float(PLAYER_HALF))

	# Color sources (ColorSource, GhostTile, SuperColorSource, RainbowTile)
	for tile: Node2D in level.color_sources.duplicate():
		if not is_instance_valid(tile):
			continue
		var offset := tile.position - position
		if offset.length_squared() > MIN_DIST_SQ:
			continue
		var th := Vector2(float(TILE_HALF), float(TILE_HALF))
		if not _boxes_touch(position, ph, tile.position, th, 3.0):
			continue
		_collect_color_tile(tile)

	# Death tiles
	var th := Vector2(float(TILE_HALF), float(TILE_HALF))
	for tile: Node2D in level.death_tiles:
		if not is_instance_valid(tile):
			continue
		if _boxes_touch(position, ph, tile.position, th, 2.0):
			_die()
			return

	# Black holes
	for tile: Node2D in level.black_holes:
		if not is_instance_valid(tile):
			continue
		if _boxes_touch(position, ph, tile.position, th, 2.0):
			var sub: Color = tile.get_meta("subtract_color", Color.WHITE)
			if ColorUtils.would_subtract(joy_color, sub):
				joy_color = ColorUtils.rgb_subtract(joy_color, sub)
				GameEvents.particles_requested.emit(
					sub, tile, 100, Vector2(-3, 3), Vector2i(2, 6), Vector2.ZERO, Vector2.ZERO
				)
				GameEvents.sound_requested.emit("res://sounds/collect.wav")

	# Update exit open state
	if level and is_instance_valid(level.exit_node):
		level.exit_node.set_open(level.has_exit_color(joy_color))

	# Exit
	if level.has_exit_color(joy_color) and level.in_exit(position, Vector2(PLAYER_HALF, PLAYER_HALF)):
		GameEvents.level_complete.emit()
		GameEvents.sound_requested.emit("res://sounds/exit.wav")

func _collect_color_tile(tile: Node2D) -> void:
	var tile_color: Color = tile.get_meta("tile_color", Color.WHITE)
	var source_type: String = tile.get_meta("source_type", "color_source")

	match source_type:
		"super_src":
			joy_color = tile_color
		"ghost":
			var weight := tile_color.a * 0.15
			joy_color = ColorUtils.blend(joy_color, tile_color, weight)
		_:  # color_source, rainbow
			joy_color = ColorUtils.blend(joy_color, tile_color)

	level.color_sources.erase(tile)
	GameEvents.particles_requested.emit(tile_color, self, 5, Vector2(-3, 3), Vector2i(2, 6), Vector2.ZERO, Vector2.ZERO)
	GameEvents.sound_requested.emit("res://sounds/collect.wav")
	if tile.get("path_nodes") != null:
		# Moving tile — clear color but keep moving
		tile.set("tile_color", Color(0.5, 0.5, 0.5, 1.0))
		tile.set_meta("tile_color", Color(0.5, 0.5, 0.5, 1.0))
		tile.queue_redraw()
	else:
		tile.queue_free()
		# Replace with solid gray tile (StaticBody2D so player can still stand on it)
		var gray := StaticBody2D.new()
		var shape_owner := gray.create_shape_owner(gray)
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		gray.shape_owner_add_shape(shape_owner, rect)
		gray.position = tile.position
		var visual := ColorRect.new()
		visual.color = Color(0.5, 0.5, 0.5, 1.0)
		visual.size = Vector2(TILE_SIZE, TILE_SIZE)
		visual.position = Vector2(-TILE_HALF, -TILE_HALF)
		gray.add_child(visual)
		level.add_child(gray)

# --- Squish helpers ---

func _trigger_squish_y(amount: float, direction: int) -> void:
	_squish_y_at = _time
	_squish_y_height = amount
	_squish_y_dir = direction
	_squish_y_amount = 0.0

func _trigger_squish_x(amount: float, direction: int) -> void:
	_squish_x_at = _time
	_squish_x_width = amount
	_squish_x_dir = direction
	_squish_x_amount = 0.0

func _update_squish(delta: float) -> void:
	if _squish_y_at >= 0:
		var dt := _time - _squish_y_at
		if dt < SQUISH_DURATION:
			if dt < SQUISH_PEAK:
				_squish_y_amount = _squish_y_height * (dt / SQUISH_PEAK)
			else:
				_squish_y_amount = _squish_y_height * (1.0 - (dt - SQUISH_PEAK) / (SQUISH_DURATION - SQUISH_PEAK))
		else:
			_squish_y_at = -1.0
			_squish_y_amount = 0.0

	if _squish_x_at >= 0:
		var dt := _time - _squish_x_at
		if dt < SQUISH_DURATION:
			if dt < SQUISH_PEAK:
				_squish_x_amount = _squish_x_width * (dt / SQUISH_PEAK)
			else:
				_squish_x_amount = _squish_x_width * (1.0 - (dt - SQUISH_PEAK) / (SQUISH_DURATION - SQUISH_PEAK))
		else:
			_squish_x_at = -1.0
			_squish_x_amount = 0.0

# --- Rendering ---

func _draw() -> void:
	var ys := _squish_y_amount / 2.0
	var y_off := ys * _squish_y_dir
	var xs := _squish_x_amount / 2.0
	var right_push := _squish_x_dir > 0
	var left_push  := _squish_x_dir < 0

	var ph := float(PLAYER_HALF)
	var x1 := -ph - ys + (xs if right_push else 0.0)
	var y1 := -ph + y_off + ys - (3.0 * xs if left_push else xs)
	var x2 :=  ph + ys + (-xs if left_push else 0.0)
	var y2 := -ph + y_off + ys - (3.0 * xs if right_push else xs)
	var x3 := x2
	var y3 :=  ph + y_off - ys
	var x4 := x1
	var y4 := y3

	# White border (1px outset)
	var border_pts := PackedVector2Array([
		Vector2(x1-1, y1-1), Vector2(x2+1, y2-1),
		Vector2(x3+1, y3+1), Vector2(x4-1, y4+1)
	])
	draw_colored_polygon(border_pts, Color.WHITE)

	# Colored quad
	var pts := PackedVector2Array([Vector2(x1,y1), Vector2(x2,y2), Vector2(x3,y3), Vector2(x4,y4)])
	draw_colored_polygon(pts, joy_color)

# --- Death ---

func _die() -> void:
	# Emit death particles (intensity 40, speed ±7, size 2–6) then signal
	GameEvents.particles_requested.emit(
		joy_color, null, 40, Vector2(-7.0, 7.0), Vector2i(2, 6), Vector2.ZERO, Vector2.ZERO
	)
	GameEvents.sound_requested.emit("res://sounds/death.wav")
	GameEvents.player_died.emit()

# --- Utility ---

static func _boxes_touch(a_pos: Vector2, a_half: Vector2, b_pos: Vector2, b_half: Vector2, buffer: float) -> bool:
	var diff := b_pos - a_pos
	return absf(diff.x) <= (a_half.x + b_half.x + buffer) and \
		   absf(diff.y) <= (a_half.y + b_half.y + buffer)
