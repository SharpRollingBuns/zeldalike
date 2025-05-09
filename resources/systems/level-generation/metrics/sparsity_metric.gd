class_name SparsityMetric
extends LevelMetric

func evaluate(level_data:Dictionary) -> float:
	var grid : PackedInt32Array = level_data["grid"]
	var floor_cells := 0
	for id in grid:
		if id != 0:     # 0 = WALL
			floor_cells += 1
	return float(floor_cells) / grid.size()

func name() -> String:
	return "Sparsity"
