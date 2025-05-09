class_name CellularAutomataGenerator
extends LevelGenerator

# -- Настраиваемые параметры ---------------------------------------------------
@export_range(0.0, 1.0, 0.01) var initial_wall_chance: float = 0.45
@export_range(0, 8, 1) var death_limit: int = 3
@export_range(0, 8, 1) var birth_limit: int = 4
@export_range(0, 10, 1) var simulation_steps: int = 5
@export var clamp_edges: bool = true
@export var seed: int = -1

# Количество ассетов -----------------------------------------
@export var door_count: int = 2
@export var chest_count: int = 3
@export var key_count: int = 1
@export var enemy_count: int = 5
@export var obstacle_count: int = 10

# -- Публичный API -------------------------------------------------------------
func generate() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()

	# ---- Генерация карты клеточным автоматом -------------------------------
	var bool_grid := _init_map(grid_width, grid_height, rng)
	for _i in range(simulation_steps):
		bool_grid = _simulate_step(bool_grid)

	# ---- Преобразование в PackedInt32Array тайлов ---------------------------
	var tile_grid := PackedInt32Array()
	tile_grid.resize(grid_width * grid_height)
	var idx := 0
	for y in range(grid_height):
		for x in range(grid_width):
			tile_grid[idx] = TileType.WALL if bool_grid[x][y] == 1 else TileType.FLOOR
			idx += 1

	# ---- Размещение ассетов -------------------------------------------------
	var floor_cells := _collect_floor_cells(bool_grid)
	var doors      := _place_doors(floor_cells, rng)
	var chests     := _pick_random_cells(floor_cells, chest_count, doors, rng)
	var keys       := _pick_random_cells(floor_cells, key_count, doors + chests, rng)
	var obstacles  := _pick_random_cells(floor_cells, obstacle_count, doors + chests + keys, rng)
	var enemies    := _pick_random_cells(floor_cells, enemy_count, doors + chests + keys + obstacles, rng)

	var level_data := {
		"grid":      tile_grid,
		"doors":     doors,
		"chests":    chests,
		"keys":      keys,
		"enemies":   enemies,
		"obstacles": obstacles,
	}
	emit_signal("finished", level_data)
	return level_data

# -- Внутренние функции --------------------------------------------------------
func _init_map(w: int, h: int, rng: RandomNumberGenerator) -> Array:
	var map := []
	for x in range(w):
		var column := []
		for _y in range(h):
			column.append(1 if rng.randf() < initial_wall_chance else 0)
		map.append(column)
	return map

func _simulate_step(map: Array) -> Array:
	var w := map.size()
	var h = map[0].size()
	var new_map := []
	for x in range(w):
		var column := []
		for y in range(h):
			var neighbours := _count_alive_neighbours(map, x, y, w, h)
			var current = map[x][y]
			if current == 1:
				column.append(1 if neighbours >= death_limit else 0)
			else:
				column.append(1 if neighbours > birth_limit else 0)
		new_map.append(column)
	return new_map

func _count_alive_neighbours(map: Array, x: int, y: int, w: int, h: int) -> int:
	var count := 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			var alive := 0
			if clamp_edges:
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					alive = 1
				else:
					alive = map[nx][ny]
			else:
				alive = map[(nx + w) % w][(ny + h) % h]
			count += alive
	return count

# -----------------------------------------------------------------------------
# Feature-placement helpers
# -----------------------------------------------------------------------------
func _collect_floor_cells(grid: Array) -> Array:
	var w := grid.size()
	var h = grid[0].size()
	var floors := []
	for x in range(w):
		for y in range(h):
			if grid[x][y] == 0:
				floors.append(Vector2i(x, y))
	return floors

func _place_doors(floors: Array, rng: RandomNumberGenerator) -> Array:
	var edge_floors := []
	for pos in floors:
		if pos.x == 0 or pos.x == grid_width - 1 or pos.y == 0 or pos.y == grid_height - 1:
			edge_floors.append(pos)
	var doors := []
	var available := edge_floors.duplicate()
	for _i in range(min(door_count, available.size())):
		var idx := rng.randi_range(0, available.size() - 1)
		doors.append(available[idx])
		available.remove_at(idx)
	return doors

func _pick_random_cells(floors: Array, count: int, exclude: Array, rng: RandomNumberGenerator) -> Array:
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

# -- Отладка -------------------------------------------------------------------
func get_ascii_map(width: int = 40, height: int = 25) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var grid := _init_map(width, height, rng)
	for _i in range(simulation_steps):
		grid = _simulate_step(grid)
	var str := ""
	for y in range(height):
		for x in range(width):
			str += "#" if grid[x][y] == 1 else "."
		str += "\n"
	return str
