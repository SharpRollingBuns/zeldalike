class_name BSPGenerator
extends LevelGenerator


# Exported tuning parameters ---------------------------------------------------
@export var max_split_depth: int = 5 # Maximum recursion depth
@export var min_room_size: Vector2i = Vector2i(6, 6) # Minimum room size (safety net)
@export_range(0.0, 1.0, 0.05) var room_min_fill_ratio: float = 0.7 # Min % of leaf size
@export var margin_inside_leaf: int = 1 # Margin between room and leaf edge
@export var corridor_width: int = 1 # Corridor width in tiles
@export var add_randomness_to_bsp: bool = true # Randomise split positions
@export var gen_seed: int = -1 # –1 → randomise RNG seed


# Asset counters ---------------------------------------------------------------
@export var door_count: int = 2
@export var chest_count: int = 3
@export var key_count: int = 1
@export var enemy_count: int = 5
@export var obstacle_count: int = 10


# Internal structures ----------------------------------------------------------
class BspNode:
	var rect: Rect2i
	var left: BspNode = null
	var right: BspNode = null
	var room_rect = null

	func _init(new_rect: Rect2i) -> void:
		self.rect = new_rect


# Public API -------------------------------------------------------------------
func generate() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if gen_seed >= 0:
		rng.seed = gen_seed
	else:
		rng.randomize()
	
	var grid := _create_filled_grid(grid_width, grid_height, 1) # 1 = WALL
	
	var root := BspNode.new(Rect2i(Vector2i.ZERO, Vector2i(grid_width, grid_height)))
	_split_node(root, 0, rng)
	_create_rooms(root, rng)
	_carve_rooms(root, grid)
	_connect_tree(root, grid, rng)
	
	var tile_grid := _bool_grid_to_tile_array(grid)
	
	var floor_cells := _collect_floor_cells(grid)
	var doors := _place_doors(floor_cells, rng)
	var chests := _pick_random_cells(floor_cells, chest_count, doors, rng)
	var keys := _pick_random_cells(floor_cells, key_count, doors + chests, rng)
	var obstacles := _pick_random_cells(
		floor_cells, obstacle_count, doors + chests + keys, rng)
	var enemies := _pick_random_cells(
		floor_cells, enemy_count, doors + chests + keys + obstacles, rng)
	
	var level_data := {
		"grid": tile_grid,
		"doors": doors,
		"chests": chests,
		"keys": keys,
		"enemies": enemies,
		"obstacles": obstacles,
	}
	emit_signal("finished", level_data)
	return level_data


# BSP helpers ------------------------------------------------------------------
func _split_node(node: BspNode, depth: int, rng: RandomNumberGenerator) -> void:
	if depth >= max_split_depth:
		return
	
	var can_split_h := node.rect.size.y >= min_room_size.y * 2
	var can_split_v := node.rect.size.x >= min_room_size.x * 2
	if not can_split_h and not can_split_v:
		return
	
	var split_horizontal := false
	if can_split_h and can_split_v:
		split_horizontal = rng.randf() < 0.5
	elif can_split_h:
		split_horizontal = true
	
	var rect_a: Rect2i
	var rect_b: Rect2i
	
	if split_horizontal:
		var max_split := node.rect.size.y - min_room_size.y * 2
		
		@warning_ignore("integer_division")
		var split_at := rng.randi_range(min_room_size.y, max_split) \
			if add_randomness_to_bsp \
			else node.rect.size.y / 2
		rect_a = Rect2i(node.rect.position, Vector2i(node.rect.size.x, split_at))
		rect_b = Rect2i(
			node.rect.position + Vector2i(0, split_at),
			Vector2i(node.rect.size.x, node.rect.size.y - split_at))
	else:
		var max_split := node.rect.size.x - min_room_size.x * 2
		
		@warning_ignore("integer_division")
		var split_at := rng.randi_range(min_room_size.x, max_split) \
			if add_randomness_to_bsp \
			else node.rect.size.x / 2
		rect_a = Rect2i(node.rect.position, Vector2i(split_at, node.rect.size.y))
		rect_b = Rect2i(
			node.rect.position + Vector2i(split_at, 0),
			Vector2i(node.rect.size.x - split_at, node.rect.size.y))
	
	node.left = BspNode.new(rect_a)
	node.right = BspNode.new(rect_b)
	
	_split_node(node.left, depth + 1, rng)
	_split_node(node.right, depth + 1, rng)


func _create_rooms(node: BspNode, rng: RandomNumberGenerator) -> void:
	if node.left or node.right:
		if node.left:
			_create_rooms(node.left, rng)
		if node.right:
			_create_rooms(node.right, rng)
		return
	
	var leaf_inner_width := node.rect.size.x - margin_inside_leaf * 2
	var leaf_inner_height := node.rect.size.y - margin_inside_leaf * 2
	if leaf_inner_width < min_room_size.x or leaf_inner_height < min_room_size.y:
		return
	
	var target_w_min := int(leaf_inner_width * room_min_fill_ratio)
	var target_h_min := int(leaf_inner_height * room_min_fill_ratio)
	
	var room_w := rng.randi_range(
		max(min_room_size.x, target_w_min), leaf_inner_width)
	var room_h := rng.randi_range(
		max(min_room_size.y, target_h_min), leaf_inner_height)
	
	var room_x := rng.randi_range(
		node.rect.position.x + margin_inside_leaf,
		node.rect.position.x + node.rect.size.x - margin_inside_leaf - room_w)
	var room_y := rng.randi_range(
		node.rect.position.y + margin_inside_leaf,
		node.rect.position.y + node.rect.size.y - margin_inside_leaf - room_h)
	
	node.room_rect = Rect2i(Vector2i(room_x, room_y), Vector2i(room_w, room_h))


func _carve_rooms(node: BspNode, grid: Array) -> void:
	if node.left or node.right:
		if node.left:
			_carve_rooms(node.left, grid)
		if node.right:
			_carve_rooms(node.right, grid)
		return
	
	if node.room_rect == null:
		return
	
	var r = node.room_rect
	for x in range(r.position.x, r.position.x + r.size.x):
		for y in range(r.position.y, r.position.y + r.size.y):
			grid[x][y] = 0 # Floor


func _connect_tree(node: BspNode, grid: Array, rng: RandomNumberGenerator) -> void:
	if node.left and node.right:
		_connect_tree(node.left, grid, rng)
		_connect_tree(node.right, grid, rng)
		_connect_rooms(node.left, node.right, grid, rng)


func _connect_rooms(
		a: BspNode, b: BspNode, grid: Array, rng: RandomNumberGenerator) -> void:
	var room_a = _find_room(a)
	var room_b = _find_room(b)
	if room_a == null or room_b == null:
		return
	
	var point_a = room_a.position + room_a.size / 2
	var point_b = room_b.position + room_b.size / 2
	
	if rng.randf() < 0.5:
		_dig_h_corridor(grid, point_a.x, point_b.x, point_a.y)
		_dig_v_corridor(grid, point_a.y, point_b.y, point_b.x)
	else:
		_dig_v_corridor(grid, point_a.y, point_b.y, point_a.x)
		_dig_h_corridor(grid, point_a.x, point_b.x, point_b.y)


func _dig_h_corridor(grid: Array, x1: int, x2: int, y: int) -> void:
	var from_x = min(x1, x2)
	var to_x = max(x1, x2)
	for x in range(from_x, to_x + 1):
		@warning_ignore("integer_division")
		for w in range(-int(corridor_width / 2), int(corridor_width / 2) + 1):
			var yy := y + w
			if _is_in_bounds(x, yy):
				grid[x][yy] = 0


func _dig_v_corridor(grid: Array, y1: int, y2: int, x: int) -> void:
	var from_y = min(y1, y2)
	var to_y = max(y1, y2)
	for y in range(from_y, to_y + 1):
		@warning_ignore("integer_division")
		for w in range(-int(corridor_width / 2), int(corridor_width / 2) + 1):
			var xx := x + w
			if _is_in_bounds(xx, y):
				grid[xx][y] = 0


func _find_room(node: BspNode):
	if node.room_rect:
		return node.room_rect
	if node.left:
		var room = _find_room(node.left)
		if room:
			return room
	if node.right:
		var room = _find_room(node.right)
		if room:
			return room
	return null


# Utility helpers --------------------------------------------------------------
func _create_filled_grid(w: int, h: int, value: int) -> Array:
	var grid := []
	grid.resize(w)
	for x in range(w):
		grid[x] = []
		grid[x].resize(h)
		grid[x].fill(value)
	return grid


func _bool_grid_to_tile_array(grid: Array) -> PackedInt32Array:
	var tile_array := PackedInt32Array()
	tile_array.resize(grid_width * grid_height)
	var idx := 0
	for y in range(grid_height):
		for x in range(grid_width):
			tile_array[idx] = TileType.WALL if grid[x][y] else TileType.FLOOR
			idx += 1
	return tile_array


func _collect_floor_cells(grid: Array) -> Array:
	var floors := []
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] == 0:
				floors.append(Vector2i(x, y))
	return floors


func _place_doors(floors: Array, rng: RandomNumberGenerator) -> Array:
	var edge_floors := []
	for pos in floors:
		if pos.x == 0 or pos.x == grid_width - 1 or pos.y == 0 or \
				pos.y == grid_height - 1:
			edge_floors.append(pos)
	
	var doors := []
	var available := edge_floors.duplicate()
	var doors_to_place = min(door_count, available.size())
	
	for _i in range(doors_to_place):
		var idx := rng.randi_range(0, available.size() - 1)
		doors.append(available[idx])
		available.remove_at(idx)
	return doors


func _pick_random_cells(
		floors: Array, count: int, exclude: Array, rng: RandomNumberGenerator) -> Array:
	if count <= 0:
		return []
	
	var exclude_set := {}
	for e in exclude:
		exclude_set[e] = true
	
	var candidates := []
	for pos in floors:
		if not exclude_set.has(pos):
			candidates.append(pos)
	
	var result := []
	while result.size() < count and candidates.size() > 0:
		var idx := rng.randi_range(0, candidates.size() - 1)
		result.append(candidates[idx])
		candidates.remove_at(idx)
	return result


func _is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height
