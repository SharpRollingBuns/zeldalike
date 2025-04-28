class_name Player extends CharacterBody2D

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO


@onready var Animation_Player : AnimationPlayer = $AnimationPlayer
@onready var Sprite : Sprite2D = $Sprite2D
@onready var state_machine : PlayeStateMachine = $StateMachine


func _ready ():
	state_machine.Initialize(self)


func _process( delta ):
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")


func _physics_process( delta ):
	move_and_slide()


func SetDirection() -> bool:
	var new_dir : Vector2 = cardinal_direction
	if direction == Vector2.ZERO:
		return false
	
	if direction.y == 0:
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
		
	if new_dir == cardinal_direction:
		return false
	cardinal_direction = new_dir
	
	Sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true


func UpdateAnimation(state : String) -> void:
	Animation_Player.play( state + "_" + AnimDirection())


func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"
