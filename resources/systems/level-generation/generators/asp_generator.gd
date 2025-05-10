class_name ASPGenerator
extends LevelGenerator

# ─────────────────────────── Параметры (таблица свойств) ─────────────────────
@export var seed               : int  = -1
@export var room_count         : int  = 12    #   rooms ≥ 2
@export var key_count          : int  = 1     #   ключей / замков
@export var allow_cycles       : bool = false #   циклы в графе
@export var max_branch_length  : int  = 6
@export var difficulty         : float = 0.5  #   0..1 (влияет на плотность ловушек)

# – распределение ассетов –
@export var door_count         : int = 2
@export var chest_count        : int = 3
@export var enemy_count        : int = 4
@export var obstacle_count     : int = 8

# – ссылка на фреймворк –
@export var asp : ASPFramework
@export var path_to_rules : String

# – временные таблицы результата –
var _grid_width  : int
var _grid_height : int

# ─────────────────────────── публичный API ───────────────────────────────────
func generate() -> Dictionary:
	randomize_seed()
	# 1) Сформировать ASP-программу
	var lp_src := _build_lp()
	
	# 2) Вызвать решатель
	var models = asp.solve(lp_src)
	if models.is_empty():
		push_error("ASP returned no model")
		return {}
		
	# 3) Распарсить первую модель
	var atoms : PackedStringArray = models[0]["Call"][0]["Witnesses"][0]["Value"]
	var level_data = _interpret_atoms(atoms)
	
	# 4) Сигнал + результат
	emit_signal("finished", level_data)
	return level_data


# ─────────────────────────── внутренние функции ──────────────────────────────
func randomize_seed():
	var rng = RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	seed = rng.seed     # сохраняем реальный сид

func _build_lp() -> String:
	var lp_text := ""
	if FileAccess.file_exists(path_to_rules):
		lp_text = FileAccess.get_file_as_string(path_to_rules)
	else:
		push_error("ASP template not found: %s" % path_to_rules)
	
	# Шаблон base.lp (см. ниже) + конкретные факты
	var sb = []
	sb.append(lp_text)
	sb.append("\n%%--- instance facts --------------------------------\n")
	sb.append("grid(%d,%d).\n" % [grid_width, grid_height])
	sb.append("rooms(%d).\n"  % room_count)
	sb.append("keys(%d).\n"    % key_count)
	sb.append("seed(%d).\n"    % seed)
	if allow_cycles:  sb.append("allow_cycles.\n")
	sb.append("difficulty(%f).\n" % difficulty)
	# … при желании добавьте door_count etc.
	return "".join(sb)

func _interpret_atoms(atoms : PackedStringArray) -> Dictionary:
	# Конечные контейнеры
	var tile_grid   := PackedInt32Array()
	var doors       : Array[Vector2i] = []
	var chests      : Array[Vector2i] = []
	var keys_arr    : Array[Vector2i] = []
	var enemies     : Array[Vector2i] = []
	var obstacles   : Array[Vector2i] = []
	
	tile_grid.resize(grid_width * grid_height)
	
	for atom in atoms:
		# примеры атомов:
		#   wall(3,7).  floor(2,5).  door(1,0).  key(9,4).  enemy(2,8).
		var m = atom.find("(")
		if m == -1: continue
		var name = atom.substr(0, m)
		var xy   = atom.substr(m+1, atom.length() - m - 2).split(",")
		var x = int(xy[0]); var y = int(xy[1])
		match name:
			"wall":   tile_grid[x + y * grid_width] = TileType.WALL
			"floor":  tile_grid[x + y * grid_width] = TileType.FLOOR
			"door":   doors.append(Vector2i(x,y))
			"chest":  chests.append(Vector2i(x,y))
			"key":    keys_arr.append(Vector2i(x,y))
			"enemy":  enemies.append(Vector2i(x,y))
			"obst":   obstacles.append(Vector2i(x,y))
	
	return {
		"grid":      tile_grid,
		"doors":     doors,
		"chests":    chests,
		"keys":      keys_arr,
		"enemies":   enemies,
		"obstacles": obstacles,
	}
