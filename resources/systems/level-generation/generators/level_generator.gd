class_name LevelGenerator
extends Resource
## Абстрактный генератор уровня.

@export var grid_width : int = 64
@export var grid_height : int = 64
@export var tile_set : TileSet     # ссылка на ваш TileSet

signal finished(level_data: Dictionary)


func generate() -> Dictionary:
	## Должен вернуть:
	## "grid"      : PackedInt32Array  # ID тайла на клетку
	## "doors"     : Array[Vector2i]
	## "chests"    : Array[Vector2i]
	## "keys"      : Array[Vector2i]
	## "enemies"   : Array[Vector2i]
	## "obstacles" : Array[Vector2i]
	push_error("Не переопределён generate()")
	return {}
