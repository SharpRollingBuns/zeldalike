class_name LevelSpawnConfig
extends Resource

@export var groups : Array[SpawnConfig] = []

func get_group(name:String) -> SpawnConfig:
	for g in groups:
		if g.group_name == name:
			return g
	return null
