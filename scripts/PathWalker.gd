class_name PathWalker

const LEFT  := Vector2i(-1,  0)
const RIGHT := Vector2i( 1,  0)
const UP    := Vector2i( 0, -1)
const DOWN  := Vector2i( 0,  1)

## Search order (left-handed wall following)
const SEARCH_ORDER: Array[Vector2i] = [LEFT, UP, RIGHT, DOWN]

## RELATIVE_DIR_MAP[current_heading][relative_dir] → absolute_dir
## Port of RELATIVE_DIR_MAP from level.rb
const RELATIVE_DIR_MAP := {
	# when heading UP
	Vector2i(0,-1): {
		Vector2i(-1, 0): Vector2i(-1, 0),  # rel LEFT  → abs LEFT
		Vector2i( 0,-1): Vector2i( 0,-1),  # rel UP    → abs UP
		Vector2i( 1, 0): Vector2i( 1, 0),  # rel RIGHT → abs RIGHT
		Vector2i( 0, 1): Vector2i( 0, 1),  # rel DOWN  → abs DOWN
	},
	# when heading RIGHT
	Vector2i(1, 0): {
		Vector2i(-1, 0): Vector2i( 0,-1),  # rel LEFT  → abs UP
		Vector2i( 0,-1): Vector2i( 1, 0),  # rel UP    → abs RIGHT
		Vector2i( 1, 0): Vector2i( 0, 1),  # rel RIGHT → abs DOWN
		Vector2i( 0, 1): Vector2i(-1, 0),  # rel DOWN  → abs LEFT
	},
	# when heading DOWN
	Vector2i(0, 1): {
		Vector2i(-1, 0): Vector2i( 1, 0),  # rel LEFT  → abs RIGHT
		Vector2i( 0,-1): Vector2i( 0, 1),  # rel UP    → abs DOWN
		Vector2i( 1, 0): Vector2i(-1, 0),  # rel RIGHT → abs LEFT
		Vector2i( 0, 1): Vector2i( 0,-1),  # rel DOWN  → abs UP
	},
	# when heading LEFT
	Vector2i(-1, 0): {
		Vector2i(-1, 0): Vector2i( 0, 1),  # rel LEFT  → abs DOWN
		Vector2i( 0,-1): Vector2i(-1, 0),  # rel UP    → abs LEFT
		Vector2i( 1, 0): Vector2i( 0,-1),  # rel RIGHT → abs UP
		Vector2i( 0, 1): Vector2i( 1, 0),  # rel DOWN  → abs RIGHT
	},
}

const NEIGHBOR_DIRS: Array[Vector2i] = [RIGHT, UP, DOWN, LEFT]

## Build an ordered closed-loop path from an unordered set of grid positions.
## start_loc must be in locs.
static func build_path(locs: Array[Vector2i], start_loc: Vector2i) -> Array[Vector2i]:
	if locs.size() <= 1:
		return locs.duplicate()

	# Find initial wall direction: first neighbor of start_loc NOT in path set
	var wall_dir := Vector2i.ZERO
	for n in NEIGHBOR_DIRS:
		if not (start_loc + n) in locs:
			wall_dir = n
			break

	# Initial movement direction: next in SEARCH_ORDER after wall_dir
	var wall_idx := SEARCH_ORDER.find(wall_dir)
	var start_dir: Vector2i = SEARCH_ORDER[(wall_idx + 1) % SEARCH_ORDER.size()]

	var path: Array[Vector2i] = []
	var loc := start_loc
	var dir := start_dir
	var first_next := Vector2i(-9999, -9999)

	while true:
		var next_loc := Vector2i(-9999, -9999)
		for rel_dir in SEARCH_ORDER:
			var heading_map: Dictionary = RELATIVE_DIR_MAP.get(dir, {})
			var abs_dir: Vector2i = heading_map.get(rel_dir, Vector2i.ZERO)
			var candidate := loc + abs_dir
			if candidate in locs:
				next_loc = candidate
				dir = abs_dir
				break

		if next_loc == Vector2i(-9999, -9999):
			break  # disconnected graph — no valid next cell found

		if loc == start_loc and next_loc == first_next and not path.is_empty():
			break

		path.append(loc)
		if first_next == Vector2i(-9999, -9999):
			first_next = next_loc
		loc = next_loc

	return path
