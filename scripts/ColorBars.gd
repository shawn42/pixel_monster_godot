extends Node2D

## Draws the RGB channel comparison bars (port of draw_color_helper_hud).
## Must be a child of the HUD CanvasLayer so it draws in screen space.

var player_color: Color = Color.BLACK
var exit_color:   Color = Color.WHITE

const FULL_H  := 60.0

func _draw() -> void:
	# Background box
	draw_rect(Rect2(-5, -FULL_H - 10, 70, FULL_H + 10),
	          Color(1, 1, 1, 0.35))

	_draw_channel(0,  exit_color.r, player_color.r, Color.RED)
	_draw_channel(20, exit_color.g, player_color.g, Color.GREEN)
	_draw_channel(40, exit_color.b, player_color.b, Color.BLUE)

	# White outline polyline
	draw_polyline(PackedVector2Array([
		Vector2(-5, -FULL_H-10), Vector2(65, -FULL_H-10),
		Vector2(65, 0),          Vector2(-5, 0),
		Vector2(-5, -FULL_H-10)
	]), Color.WHITE, 1.0)

func _draw_channel(x_off: float, exit_val: float, player_val: float, c: Color) -> void:
	# Faint exit bar (background)
	var eh := exit_val * FULL_H + 1
	var fc := Color(c.r, c.g, c.b, 0.2)
	draw_rect(Rect2(x_off, -eh, 20, eh), fc)
	# Solid player bar (foreground)
	var ph := player_val * FULL_H
	draw_rect(Rect2(x_off + 5, -ph, 10, ph), c)
