class_name State_Idle extends State

@onready var walk : State = $"../Walk"
@onready var attack : State = $"../Attack"



#What happens when the player enters this state
func Enter() -> void:
	player.UpdateAnimation("idle")
		
#What happens when the player exits this state
func Exit() -> void:
		pass


func Process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null
	
func Psysics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("attack"):
		return attack
	return null
