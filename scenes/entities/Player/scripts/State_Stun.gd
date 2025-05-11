class_name State_Stun
extends State

@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0
@export var invulnerable_durection: float = 1.0

@onready var idle : State =$"../Idle"

var hurt_box: HurtBox
var direction: Vector2

var next_state : State = null


func init() -> void:
	player.player_damaged.connect(_player_damaged)
	pass


func Enter() -> void:
	player.Animation_Player.animation_finished.connect(_animation_finished)
	
	direction = player.global_position.direction_to(hurt_box.global_position)
	player.velocity = direction * -knockback_speed
	player.SetDirection()
	player.UpdateAnimation("stun")
	
	player.make_invulnerable(invulnerable_durection)
	player.effect_animation_player.play("damaged")
	pass


func Exit() -> void:
	next_state = null
	player.Animation_Player.animation_finished.disconnect(_animation_finished)
	pass


func Process(_delta: float) -> State:
	player.velocity -=player.velocity * decelerate_speed * _delta
	return next_state


func Physics(_delta: float) -> State:
	return null


func HandleInput(_event: InputEvent) -> State:
	return null


func _player_damaged (_hurt_box : HurtBox) -> void:
	hurt_box = _hurt_box
	state_machine.ChangeState(self)


func _animation_finished(_a : String ) -> void:
	next_state = idle
