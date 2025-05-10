class_name LevelGenerator
extends Resource
## Абстрактный генератор уровня.

@export var grid_width : int = 35
@export var grid_height : int = 20

@warning_ignore("unused_variable", "unused_signal")
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
