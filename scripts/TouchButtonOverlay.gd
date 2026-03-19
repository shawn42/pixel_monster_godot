extends Control

const BUTTON_SIZE := 240.0
const BUTTON_MARGIN := 15.0
const BUTTON_Y_OFFSET := 280.0
const ARROW_COLOR := Color(1, 1, 1, 0.3)
const PRESSED_COLOR := Color(1, 1, 1, 0.6)

var _parent: Node = null

func _ready() -> void:
	_parent = get_parent()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchors_preset = Control.PRESET_FULL_RECT

func _process(_delta: float) -> void:
	queue_redraw()

const LEFT_GUTTER  := 550.0
const RIGHT_GUTTER := 400.0

func _draw() -> void:
	if not _parent:
		return
	var vs := get_viewport_rect().size
	var left_pressed: bool = _parent._left_pressed if _parent else false
	var right_pressed: bool = _parent._right_pressed if _parent else false

	# Black gutter backgrounds
	draw_rect(Rect2(0, 0, LEFT_GUTTER, vs.y), Color.BLACK)
	draw_rect(Rect2(vs.x - RIGHT_GUTTER, 0, RIGHT_GUTTER, vs.y), Color.BLACK)

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
