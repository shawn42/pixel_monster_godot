extends SceneTree

const ColorUtilsScript = preload("res://scripts/autoloads/ColorUtils.gd")

func _init() -> void:
	_test_blend()
	_test_would_subtract()
	_test_rgb_subtract()
	_test_average_color()
	_test_color_hue()
	print("All ColorUtils tests passed!")
	quit(0)

func _test_blend() -> void:
	# blend BLACK toward RED with weight 0.15 → r=0.15, g=0, b=0
	var result := ColorUtilsScript.blend(Color.BLACK, Color.RED, 0.15)
	assert(absf(result.r - 0.15) < 0.001, "blend r")
	assert(absf(result.g) < 0.001,         "blend g stays 0")
	assert(absf(result.b) < 0.001,         "blend b stays 0")
	# weight=0 → no change
	var unchanged := ColorUtilsScript.blend(Color.RED, Color.BLUE, 0.0)
	assert(absf(unchanged.r - 1.0) < 0.001, "blend weight=0 unchanged")
	print("  _test_blend: PASS")

func _test_would_subtract() -> void:
	# sub has red, base has red → true
	assert(ColorUtilsScript.would_subtract(Color.RED, Color.RED),         "would_subtract true")
	# sub has red, base has no red → false
	assert(!ColorUtilsScript.would_subtract(Color(0,1,0,1), Color.RED),   "would_subtract false: no shared channel")
	# sub is black → false
	assert(!ColorUtilsScript.would_subtract(Color.WHITE, Color.BLACK),    "would_subtract false: sub is black")
	print("  _test_would_subtract: PASS")

func _test_rgb_subtract() -> void:
	# WHITE minus RED → (0, 1, 1)
	var result := ColorUtilsScript.rgb_subtract(Color.WHITE, Color.RED)
	assert(absf(result.r) < 0.001,         "subtract r clamped")
	assert(absf(result.g - 1.0) < 0.001,   "subtract g unchanged")
	assert(absf(result.b - 1.0) < 0.001,   "subtract b unchanged")
	# cannot go below 0
	var clamped := ColorUtilsScript.rgb_subtract(Color(0.1, 0, 0, 1), Color.RED)
	assert(clamped.r >= 0.0, "subtract clamps to 0")
	print("  _test_rgb_subtract: PASS")

func _test_average_color() -> void:
	var colors: Array[Color] = [Color.RED, Color.BLUE]
	var avg := ColorUtilsScript.average_color(colors)
	assert(absf(avg.r - 0.5) < 0.001, "average r")
	assert(absf(avg.g) < 0.001,       "average g")
	assert(absf(avg.b - 0.5) < 0.001, "average b")
	# empty array → BLACK
	var empty: Array[Color] = []
	var black := ColorUtilsScript.average_color(empty)
	assert(black == Color.BLACK, "average empty → BLACK")
	print("  _test_average_color: PASS")

func _test_color_hue() -> void:
	# pure red hue ≈ 0.0
	var h := ColorUtilsScript.color_hue(Color.RED)
	assert(absf(h) < 0.01 or absf(h - 1.0) < 0.01, "hue of RED ≈ 0")
	# pure green hue ≈ 0.333
	var hg := ColorUtilsScript.color_hue(Color.GREEN)
	assert(absf(hg - 0.333) < 0.01, "hue of GREEN ≈ 0.333")
	print("  _test_color_hue: PASS")
