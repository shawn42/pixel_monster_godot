extends Node

## Port of blend_colors / subtract_colors / would_subtract? from monster_system.rb
## All Color channels are 0.0–1.0 floats in GDScript.

static func blend(base: Color, absorbed: Color, weight: float = 0.15) -> Color:
	# base + (absorbed - base) * weight  — identical to Ruby: base.x + (absorbed.x - base.x)*weight
	return base.lerp(absorbed, weight)

static func would_subtract(base: Color, sub: Color) -> bool:
	# port of would_subtract? — true if any channel of sub would reduce base
	return (sub.r > 0.0 and base.r > 0.0) or \
	       (sub.g > 0.0 and base.g > 0.0) or \
	       (sub.b > 0.0 and base.b > 0.0)

static func rgb_subtract(base: Color, sub: Color) -> Color:
	# port of subtract_colors — simple per-channel subtraction, clamped to 0
	return Color(
		maxf(base.r - sub.r, 0.0),
		maxf(base.g - sub.g, 0.0),
		maxf(base.b - sub.b, 0.0),
		1.0
	)

static func average_color(colors: Array[Color]) -> Color:
	if colors.is_empty():
		return Color.BLACK
	var r := 0.0
	var g := 0.0
	var b := 0.0
	for c: Color in colors:
		r += c.r
		g += c.g
		b += c.b
	var n := float(colors.size())
	return Color(r / n, g / n, b / n, 1.0)

static func color_hue(c: Color) -> float:
	return c.h  # Godot Color.h returns 0.0–1.0

static func has_exit_color(player_color: Color, exit_color: Color) -> bool:
	# port of has_exit_color? — average channel diff < 20/255
	var threshold := 20.0 / 255.0
	var diff := (absf(player_color.r - exit_color.r) + \
	             absf(player_color.g - exit_color.g) + \
	             absf(player_color.b - exit_color.b)) / 3.0
	return diff < threshold
