extends Control

const BUTTON_SIZE := 240.0
const BUTTON_MARGIN := 15.0
const BUTTON_Y_OFFSET := 280.0
const ARROW_COLOR := Color(1, 1, 1, 0.3)
const PRESSED_COLOR := Color(1, 1, 1, 0.6)
const TOP_BTN_SIZE := 120.0
const TOP_BTN_Y := 30.0
const LABEL_COLOR := Color(1, 1, 1, 0.3)

var _parent: Node = null

func _ready() -> void:
	_parent = get_parent()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchors_preset = Control.PRESET_FULL_RECT

func _process(_delta: float) -> void:
	queue_redraw()

const LEFT_GUTTER  := 550.0
const RIGHT_GUTTER := 550.0

func _draw() -> void:
	if not _parent:
		return
	var vs := get_viewport_rect().size
	var left_pressed: bool = _parent._left_pressed if _parent else false
	var right_pressed: bool = _parent._right_pressed if _parent else false

	# Black gutter backgrounds
	draw_rect(Rect2(0, 0, LEFT_GUTTER, vs.y), Color.BLACK)
	var jump_pressed: bool = _parent._jump_touch_id >= 0 if _parent else false
	# Right gutter: all black background
	var rg_x := vs.x - RIGHT_GUTTER
	draw_rect(Rect2(rg_x, 0, RIGHT_GUTTER, vs.y), Color.BLACK)

	# Jump button: double-wide, matching L/R style
	var jump_w := BUTTON_SIZE * 2.0 + BUTTON_MARGIN
	var jx := rg_x + (RIGHT_GUTTER - jump_w) / 2.0
	var jy := vs.y - BUTTON_Y_OFFSET
	draw_rect(Rect2(jx, jy, jump_w, BUTTON_SIZE), PRESSED_COLOR if jump_pressed else Color(1, 1, 1, 0.1))
	var jc := Vector2(jx + jump_w / 2.0, jy + BUTTON_SIZE / 2.0)
	_draw_jump_icon(jc, PRESSED_COLOR if jump_pressed else ARROW_COLOR)

	# Restart button (top-left)
	var rst_x := BUTTON_MARGIN
	var rst_y := TOP_BTN_Y
	draw_rect(Rect2(rst_x, rst_y, TOP_BTN_SIZE, TOP_BTN_SIZE), Color(1, 1, 1, 0.1))
	_draw_restart_icon(Vector2(rst_x + TOP_BTN_SIZE / 2, rst_y + TOP_BTN_SIZE / 2), LABEL_COLOR)

	# Skip button (top, next to restart)
	var skip_x := BUTTON_MARGIN + TOP_BTN_SIZE + BUTTON_MARGIN
	var skip_y := TOP_BTN_Y
	draw_rect(Rect2(skip_x, skip_y, TOP_BTN_SIZE, TOP_BTN_SIZE), Color(1, 1, 1, 0.1))
	_draw_skip_icon(Vector2(skip_x + TOP_BTN_SIZE / 2, skip_y + TOP_BTN_SIZE / 2), LABEL_COLOR)

	# Exit button (top, next to skip) — hidden on iOS per Apple guidelines
	if OS.get_name() != "iOS":
		var exit_x := BUTTON_MARGIN + (TOP_BTN_SIZE + BUTTON_MARGIN) * 2
		var exit_y := TOP_BTN_Y
		draw_rect(Rect2(exit_x, exit_y, TOP_BTN_SIZE, TOP_BTN_SIZE), Color(1, 1, 1, 0.1))
		_draw_exit_icon(Vector2(exit_x + TOP_BTN_SIZE / 2, exit_y + TOP_BTN_SIZE / 2), LABEL_COLOR)

	# Left button background
	var lx := BUTTON_MARGIN
	var ly := vs.y - BUTTON_Y_OFFSET
	draw_rect(Rect2(lx, ly, BUTTON_SIZE, BUTTON_SIZE), PRESSED_COLOR if left_pressed else Color(1, 1, 1, 0.1))
	# Left arrow
	var lc := Vector2(lx + BUTTON_SIZE / 2, ly + BUTTON_SIZE / 2)
	var arrow_col := PRESSED_COLOR if left_pressed else ARROW_COLOR
	_draw_arrow(lc, -1, arrow_col)

	# Right button background
	var rx := BUTTON_MARGIN + BUTTON_SIZE + BUTTON_MARGIN
	var ry := vs.y - BUTTON_Y_OFFSET
	draw_rect(Rect2(rx, ry, BUTTON_SIZE, BUTTON_SIZE), PRESSED_COLOR if right_pressed else Color(1, 1, 1, 0.1))
	# Right arrow
	var rc := Vector2(rx + BUTTON_SIZE / 2, ry + BUTTON_SIZE / 2)
	arrow_col = PRESSED_COLOR if right_pressed else ARROW_COLOR
	_draw_arrow(rc, 1, arrow_col)

func _draw_arrow(center: Vector2, direction: int, color: Color) -> void:
	var size := 70.0
	var half := size / 2.0
	# Triangle pointing left (-1) or right (+1)
	var tip := center + Vector2(direction * half, 0)
	var top := center + Vector2(-direction * half, -half)
	var bot := center + Vector2(-direction * half, half)
	draw_colored_polygon(PackedVector2Array([tip, top, bot]), color)

func _draw_restart_icon(center: Vector2, color: Color) -> void:
	# Circular arrow: arc + arrowhead
	var radius := 25.0
	var points := PackedVector2Array()
	for i in range(21):
		var angle := -PI * 0.8 + (i / 20.0) * PI * 1.4
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_polyline(points, color, 3.0)
	# Arrowhead at the end of the arc
	var end_angle := -PI * 0.8 + PI * 1.4
	var tip := center + Vector2(cos(end_angle), sin(end_angle)) * radius
	var perp := Vector2(-sin(end_angle), cos(end_angle))
	var back := Vector2(cos(end_angle), sin(end_angle))
	draw_colored_polygon(PackedVector2Array([
		tip + perp * 10.0,
		tip - back * 14.0,
		tip - perp * 4.0,
	]), color)

func _draw_skip_icon(center: Vector2, color: Color) -> void:
	# Double right-pointing triangle + bar (skip icon)
	var s := 22.0
	# First triangle
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-s, -s),
		center + Vector2(0, 0),
		center + Vector2(-s, s),
	]), color)
	# Second triangle
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -s),
		center + Vector2(s, 0),
		center + Vector2(0, s),
	]), color)
	# End bar
	draw_rect(Rect2(center.x + s + 2, center.y - s, 5, s * 2), color)

func _draw_exit_icon(center: Vector2, color: Color) -> void:
	# X shape
	var s := 20.0
	var w := 4.0
	draw_line(center + Vector2(-s, -s), center + Vector2(s, s), color, w)
	draw_line(center + Vector2(s, -s), center + Vector2(-s, s), color, w)

func _draw_jump_icon(center: Vector2, color: Color) -> void:
	# Upward arrow — same size/style as _draw_arrow but pointing up
	var size := 70.0
	var half := size / 2.0
	var tip := center + Vector2(0, -half)
	var bot_l := center + Vector2(-half, half)
	var bot_r := center + Vector2(half, half)
	draw_colored_polygon(PackedVector2Array([tip, bot_l, bot_r]), color)
