class_name RandomRoomGenerator
extends LevelGenerator


@export var room_attempts : int = 80
@export var min_room      : Vector2i = Vector2i(4, 4)
@export var max_room      : Vector2i = Vector2i(10, 10)


func generate() -> Dictionary:
	var grid := PackedInt32Array()
	grid.resize(grid_width * grid_height)
	grid.fill(TileType.WALL)

	var rooms : Array[Rect2i] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for _i in room_attempts:
		var size = Vector2i(
			rng.randi_range(min_room.x, max_room.x),
			rng.randi_range(min_room.y, max_room.y))
		var pos  = Vector2i(
			rng.randi_range(1, grid_width - size.x - 1),
			rng.randi_range(1, grid_height - size.y - 1))
		var rect := Rect2i(pos, size)
		if _intersects(rect, rooms):
			continue
		rooms.append(rect)
		_carve_room(rect, grid)

	_connect_rooms(rooms, grid)

	return {
		"grid"    : grid,
		"doors"   : _pick_from_rooms(rooms, rng, 2),
		"enemies" : _pick_from_rooms(rooms, rng, 5)
	}


func _intersects(rect: Rect2i, pool: Array) -> bool:
	for r in pool:
		if r.grow(1).intersects(rect):
			return true
	return false


func _carve_room(r: Rect2i, grid: PackedInt32Array) -> void:
	for y in r.size.y:
		for x in r.size.x:
			grid[(r.position.y + y) * grid_width + (r.position.x + x)] = TileType.FLOOR


func _connect_rooms(rooms: Array, grid: PackedInt32Array) -> void:
	rooms.sort_custom(func(a,b): return a.position.x < b.position.x)
	for i in range(rooms.size() - 1):
		var c1 = rooms[i].position + rooms[i].size / 2
		var c2 = rooms[i+1].position + rooms[i+1].size / 2
		_dig_tunnel_x(c1.x, c2.x, c1.y, grid)
		_dig_tunnel_y(c1.y, c2.y, c2.x, grid)


func _dig_tunnel_x(x1: int, x2: int, y: int, grid: PackedInt32Array):
	for x in range(min(x1, x2), max(x1, x2) + 1):
		grid[y * grid_width + x] = TileType.FLOOR


func _dig_tunnel_y(y1: int, y2: int, x: int, grid: PackedInt32Array):
	for y in range(min(y1, y2), max(y1, y2) + 1):
		grid[y * grid_width + x] = TileType.FLOOR


func _pick_from_rooms(rooms: Array, rng: RandomNumberGenerator, n: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for _i in n:
		var room = rooms[rng.randi_range(0, rooms.size() - 1)]
		var pos := Vector2i(
			rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
			rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2))
		out.append(pos)
	return out
