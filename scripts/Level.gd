extends Node2D
class_name Level

const TILE_SIZE := 32
const ColorUtilsScript = preload("res://scripts/autoloads/ColorUtils.gd")

## Typed arrays — populated by LevelLoader, queried by Player each frame
var color_sources: Array[Node2D] = []
var moving_tiles:  Array[Node2D] = []
var death_tiles:   Array[Node2D] = []
var black_holes:   Array[Node2D] = []
var bouncy_tiles:  Array[Node2D] = []
var exit_node: Node2D
var player: Node2D

## Level metadata
var map_width:  int
var map_height: int
var exit_color: Color
var exit_grid_pos: Vector2i
var average_color: Color

## Grid of blocked positions: Vector2i → true
## Populated from PNG data at load time, parallel to StaticBody2D tile creation.
## Used for non-physics queries (exit detection, death tile AABB, fall detection).
var tile_map: Dictionary = {}

## Background blob pool — managed by Level in _process
var _blobs: Array[Node2D] = []
const BLOB_POOL_SIZE := 8

func _process(delta: float) -> void:
	_update_blobs(delta)

## Returns true if the grid cell at grid_pos is a solid/blocked tile.
func is_blocked(grid_pos: Vector2i) -> bool:
	return tile_map.get(grid_pos, false)

## Returns true if world_pos (player center) overlaps the exit tile.
## size is half-extents of player box (e.g. Vector2(7, 7) for 14x14 player).
func in_exit(world_pos: Vector2, size: Vector2) -> bool:
	var ex := float(exit_grid_pos.x * TILE_SIZE + TILE_SIZE / 2)
	var ey := float(exit_grid_pos.y * TILE_SIZE + TILE_SIZE / 2)
	var exit_half := 14.0  # exit tile is 14x14 (inner box)
	return absf(world_pos.x - ex) <= (size.x + exit_half) and \
	       absf(world_pos.y - ey) <= (size.y + exit_half)

## Returns true if player_color is close enough to exit_color to win.
## Match: average per-channel diff < 20/255 (port of has_exit_color?).
func has_exit_color(player_color: Color) -> bool:
	return ColorUtilsScript.has_exit_color(player_color, exit_color)

## ---- Background blob management (port of BackgroundSystem) ----

func _update_blobs(delta: float) -> void:
	# Remove out-of-bounds blobs
	for blob in _blobs.duplicate():
		if not is_instance_valid(blob):
			_blobs.erase(blob)
			continue
		var p: Vector2 = blob.position
		if p.x < -500 or p.x > 1524 or p.y < -500 or p.y > 1524:
			blob.queue_free()
			_blobs.erase(blob)

	# Spawn replacements to maintain pool of 8
	while _blobs.size() < BLOB_POOL_SIZE:
		_spawn_blob()

func _spawn_blob() -> void:
	const BlobScene = preload("res://scenes/BackgroundBlob.tscn")
	var blob: Node2D = BlobScene.instantiate()
	# Position near screen edges
	var x: float = [randf_range(0, 400), randf_range(624, 1024)].pick_random()
	var y: float = [randf_range(0, 400), randf_range(624, 1024)].pick_random()
	blob.position = Vector2(x, y)
	# Color = average level color ±5 RGB
	var c := average_color
	var r := clampf(c.r + randf_range(-5.0/255, 5.0/255), 0.0, 1.0)
	var g := clampf(c.g + randf_range(-5.0/255, 5.0/255), 0.0, 1.0)
	var b := clampf(c.b + randf_range(-5.0/255, 5.0/255), 0.0, 1.0)
	var a := randf_range(10.0/255, 70.0/255)
	blob.blob_color = Color(r, g, b, a)
	blob.blob_size  = Vector2(randf_range(100, 300), randf_range(100, 300))
	blob.velocity   = Vector2(randf_range(-5, 5), randf_range(-5, 5))
	add_child(blob)
	move_child(blob, 0)  # z-index 0: behind everything
	_blobs.append(blob)
