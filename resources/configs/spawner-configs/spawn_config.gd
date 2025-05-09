class_name SpawnConfig
extends Resource

@export var group_name : String        # ключ, приходящий из генератора
@export var scene : PackedScene   # что инстанцировать
@export var z_index : int = 0       # порядок отрисовки (опц.)
