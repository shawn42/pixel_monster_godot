extends CharacterBody2D
class_name Player

const GRAVITY        := 0.75
const MAX_VEL        := 15.0
const JUMP_FORCE     := -15.0
const SUPER_JUMP     := -25.0
const JUMP_FORGIVE   := 0.100  # 100ms
const RUN_FORGIVE    := 0.020  # 20ms
const LATERAL_ACCEL  := 1000.0 / 17.0  # ms-equivalent: Ruby used dt_ms/17.0

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
const SQUISH_MAX      := 8.0

var _time := 0.0
var _on_moving_tile := false
var _moving_tile_vel := Vector2.ZERO

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
		accel *= 0.5

	var old_vx := velocity.x
	if Input.is_action_pressed("move_left"):
		velocity.x -= accel
	elif Input.is_action_pressed("move_right"):
		velocity.x += accel

	velocity.x = clampf(velocity.x, -MAX_VEL, MAX_VEL)

	# --- Friction ---
	if not _on_moving_tile:
		if is_on_floor():
			velocity.x *= 0.9
		else:
			velocity.x *= 0.7

	# --- Jump ---
	var can_jump := (_time - _last_grounded_at) < JUMP_FORGIVE
	if Input.is_action_just_pressed("jump") and can_jump:
		var force := SUPER_JUMP if _next_jump_boosted else JUMP_FORCE
		_last_jump_force = force
		_next_jump_boosted = false
		_last_grounded_at = -1.0
		velocity.y = force
		_trigger_squish_y(-velocity.y / MAX_VEL * SQUISH_MAX, 1)
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
		_trigger_squish_y(maxf(old_vy, 6.0) / MAX_VEL * SQUISH_MAX, 1)
		GameEvents.sound_requested.emit("res://sounds/collect.wav")
	elif velocity.y == 0 and old_vy < 0:
		_trigger_squish_y(maxf(-old_vy, 6.0) / MAX_VEL * SQUISH_MAX, -1)

	# X-hit (wall)
	if velocity.x == 0 and absf(old_vx) > 0 and not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		_trigger_squish_x(maxf(absf(old_vx), 6.0) / MAX_VEL * SQUISH_MAX, sign(old_vx) as int)

	# --- Fall off map ---
	if position.y > 1100:
		_die()

	# --- Tile interactions ---
	if level:
		_check_tile_interactions()

	# --- Level actions ---
	if Input.is_action_just_pressed("skip_level"):
		GameEvents.level_complete.emit()  # skip = immediate next level
	if Input.is_action_just_pressed("reset"):
		_die()

func _process(delta: float) -> void:
	_update_squish(delta)
	queue_redraw()

func _check_moving_tile_below(delta: float) -> void:
	for tile: Node2D in level.moving_tiles:
		if not is_instance_valid(tile):
			continue
		var tp: Vector2 = tile.position
		var pw: Vector2 = position
		# "on top of" check: player bottom within 1px of tile top
		if absf(pw.x - tp.x) <= 23 and absf((pw.y + 7) - (tp.y - 16)) <= 1:
			_on_moving_tile = true
			var tv: Vector2 = tile.get_meta("velocity", Vector2.ZERO)
			_moving_tile_vel = tv
			# Interpolate X velocity toward tile X over 150ms
			var x_scale := clampf(delta / 0.15, 0.0, 1.0)
			velocity.x += (tv.x - velocity.x) * x_scale
			# Set Y directly
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
		if absf(position.x - tp.x) <= 23 and absf((position.y + 7) - (tp.y - 16)) <= 2:
			_next_jump_boosted = true
			return
	_next_jump_boosted = false

func _check_tile_interactions() -> void:
	const MIN_DIST_SQ := 80.0 * 80.0
	const PLAYER_HALF := Vector2(7.0, 7.0)

	# Color sources (ColorSource, GhostTile, SuperColorSource, RainbowTile)
	for tile: Node2D in level.color_sources.duplicate():
		if not is_instance_valid(tile):
			continue
		var offset := tile.position - position
		if offset.length_squared() > MIN_DIST_SQ:
			continue
		var tile_half := Vector2(8.0, 8.0)
		if not _boxes_touch(position, PLAYER_HALF, tile.position, tile_half, 3.0):
			continue
		_collect_color_tile(tile)

	# Death tiles
	for tile: Node2D in level.death_tiles:
		if not is_instance_valid(tile):
			continue
		if _boxes_touch(position, PLAYER_HALF, tile.position, Vector2(8.0, 8.0), 2.0):
			_die()
			return

	# Black holes
	for tile: Node2D in level.black_holes:
		if not is_instance_valid(tile):
			continue
		if _boxes_touch(position, PLAYER_HALF, tile.position, Vector2(8.0, 8.0), 0.0):
			var sub: Color = tile.get_meta("subtract_color", Color.WHITE)
			if ColorUtils.would_subtract(joy_color, sub):
				joy_color = ColorUtils.rgb_subtract(joy_color, sub)
				GameEvents.particles_requested.emit(
					sub, tile, 100, Vector2(-3, 3), Vector2i(1, 3)
				)
				GameEvents.sound_requested.emit("res://sounds/collect.wav")

	# Exit
	if level.has_exit_color(joy_color) and level.in_exit(position, PLAYER_HALF):
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
	GameEvents.particles_requested.emit(tile_color, self, 5, Vector2(-3, 3), Vector2i(1, 3))
	GameEvents.sound_requested.emit("res://sounds/collect.wav")
	tile.queue_free()

	# Replace with gray static tile
	var gray := ColorRect.new()
	gray.color = Color(0.5, 0.5, 0.5, 1)
	gray.size = Vector2(32, 32)
	gray.position = tile.position - Vector2(16, 16)
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

	var x1 := -7.0 - ys + (xs if right_push else 0.0)
	var y1 := -7.0 + y_off + ys - (3.0 * xs if left_push else xs)
	var x2 :=  7.0 + ys + (-xs if left_push else 0.0)
	var y2 := -7.0 + y_off + ys - (3.0 * xs if right_push else xs)
	var x3 := x2
	var y3 :=  7.0 + y_off - ys
	var x4 := x1
	var y4 := y3

	# White border (1px outset)
	var border_pts := PackedVector2Array([
		Vector2(x1-1, y1-1), Vector2(x2+1, y2-1),
		Vector2(x3+1, y3+1), Vector2(x4-1, y4+1)
	])
	draw_colored_polygon(border_pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]))

	# Colored quad
	var pts := PackedVector2Array([Vector2(x1,y1), Vector2(x2,y2), Vector2(x3,y3), Vector2(x4,y4)])
	draw_colored_polygon(pts, PackedColorArray([joy_color, joy_color, joy_color, joy_color]))

# --- Death ---

func _die() -> void:
	# Emit death particles (intensity 40, speed ±7, size 2–6) then signal
	GameEvents.particles_requested.emit(
		joy_color, null, 40, Vector2(-7.0, 7.0), Vector2i(2, 6)
	)
	GameEvents.sound_requested.emit("res://sounds/death.wav")
	GameEvents.player_died.emit()

# --- Utility ---

static func _boxes_touch(a_pos: Vector2, a_half: Vector2, b_pos: Vector2, b_half: Vector2, buffer: float) -> bool:
	var diff := b_pos - a_pos
	return absf(diff.x) <= (a_half.x + b_half.x + buffer) and \
	       absf(diff.y) <= (a_half.y + b_half.y + buffer)
