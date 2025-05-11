class_name HitBox extends Area2D


signal Damaged (hurt_box : HurtBox)


func TakeDamage (hurt_box : HurtBox) -> void:
	Damaged.emit(hurt_box)
