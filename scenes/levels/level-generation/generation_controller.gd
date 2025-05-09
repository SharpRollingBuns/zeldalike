class_name GenerationController
extends Node

@export var generator : LevelGenerator
@export var spawn_config : LevelSpawnConfig
@export var metrics : Array[LevelMetric] = []

@onready var floor_layer : TileMapLayer = %TileLayers/Floor
@onready var wall_layer : TileMapLayer = %TileLayers/Walls
@onready var entities = %Entities

var last_grid : PackedInt32Array


func _ready() -> void:
	regenerate()


func regenerate() -> void:
	if generator == null or spawn_config == null:
		push_error("Generator или конфиг не назначен!")
		return
	var data := generator.generate()
	last_grid = data["grid"]
	_paint_layers(last_grid)
	_spawn_entities(data)
	_evaluate_metrics(data)


func _paint_layers(grid: PackedInt32Array) -> void:
	floor_layer.clear()
	wall_layer.clear()
	var w := generator.grid_width
	for y in generator.grid_height:
		for x in w:
			var id := grid[y * w + x]
			match id:
				0: wall_layer.set_cell(Vector2i(x, y), 0, Vector2(0, 0))
				1: floor_layer.set_cell(Vector2i(x, y), 1, Vector2(0, 0))
	floor_layer.notify_runtime_tile_data_update()
	wall_layer.notify_runtime_tile_data_update()


func _spawn_entities(data: Dictionary) -> void:
	for key in data.keys():
		var cfg := spawn_config.get_group(key)
		if cfg == null:
			push_warning("Нет конфига для группы '%s'" % key)
			continue
		_spawn_group(data[key], cfg.scene, cfg.z_index)

func _spawn_group(list: Array, scene: PackedScene, z: int) -> void:
	for cell in list:
		var inst := scene.instantiate()
		inst.z_index = z
		inst.position = floor_layer.map_to_local(cell)
		entities.add_child(inst)


func _evaluate_metrics(data: Dictionary) -> void:
	for m in metrics:
		var value := m.evaluate(data)
		print("[%s] %.3f" % [m.name(), value])
