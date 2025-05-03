class_name State extends Node

static var player: Player


func _ready():
	pass


func Enter() -> void:
	pass


func Exit() -> void:
	pass


func Process(_delta: float) -> State:
	return null


func Psysics(_delta: float) -> State:
	return null


func HandleInput(_delta: InputEvent) -> State:
	return null
