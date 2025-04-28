class_name State extends Node

# Stores a reference to the player that this state belongs to
static var player: Player


func _ready():
	pass


# What happens when the player enters this state
func Enter() -> void:
	pass


# What happens when the player exits this state
func Exit() -> void:
	pass


func Process(_delta: float) -> State:
	return null


func Psysics(_delta: float) -> State:
	return null


func HandleInput(_delta: InputEvent) -> State:
	return null
