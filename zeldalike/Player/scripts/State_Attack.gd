class_name State_Attack extends State

var attacking : bool = false

@export var attack_sound : AudioStream 
@export_range(1,20,0.5) var decelarate_speed : float = 5.0

@onready var walk : State = $"../Walk"
@onready var animation_player : AnimationPlayer = $"../../AnimationPlayer"
@onready var idle : State = $"../Idle"
@onready var audio : AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"
@onready var attack_anim : AnimationPlayer = $"../../Sprite2D/AttackEffectSprite/AnimationPlayer"

#What happens when the player enters this state
func Enter() -> void:
	player.UpdateAnimation("attack")
	attack_anim.play("attack_" + player.AnimDirection())
	animation_player.animation_finished.connect(EndAttack)
	
	audio.stream = attack_sound
	audio.pitch_scale = randf_range(0.9, 1.1)
	audio.play()
	
	attacking = true
		
#What happens when the player exits this state
func Exit() -> void:
	animation_player.animation_finished.disconnect(EndAttack)
	attacking = false


func Process(_delta: float) -> State:
	player.velocity -= player.velocity * decelarate_speed * _delta
	
	if attacking ==false:
		if player.direction ==Vector2.ZERO:
			return idle
		else: 
			return walk
	return null
	
func Psysics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	return null

func EndAttack( _NewAnimName : String) -> void:
	attacking = false
	
