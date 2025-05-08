class_name Plant extends Node2D


func _ready():
	$HitBox.Damaged.connect(TakeDamage)


func TakeDamage (_damage : int) -> void:
	queue_free()
