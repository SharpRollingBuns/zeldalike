class_name Player extends CharacterBody2D

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var invulnerable :bool = false
var hp : int = 6
var max_hp : int = 6

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]


@onready var Animation_Player : AnimationPlayer = $AnimationPlayer
@onready var Sprite : Sprite2D = $Sprite2D
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer

@onready var state_machine : PlayeStateMachine = $StateMachine
@onready var hit_box: HitBox = $HitBox


signal DirectionChanged(new_direction:Vector2)
signal player_damaged(hurt_box : HurtBox)


func _ready ():
	state_machine.Initialize( self)
	PlayerManager.player = self
	hit_box.Damaged.connect(_take_damage)
	update_hp(99)


func _process( _delta ):
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")


func _physics_process( _delta ):
	move_and_slide()


func SetDirection() -> bool:
	if direction == Vector2.ZERO:
		return false
	
	var direction_id : int=int(round((direction+cardinal_direction*0.1).angle()/TAU*DIR_4.size()))
	var new_dir = DIR_4[direction_id]
	
		
	if new_dir == cardinal_direction:
		return false
	cardinal_direction = new_dir
	DirectionChanged.emit(new_dir)
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


func _take_damage(hurt_box : HurtBox) -> void:
	if invulnerable ==true:
		return
	update_hp(-hurt_box.damage)
	
	if hp>0:
		player_damaged.emit(hurt_box)
	else:
		player_damaged.emit(hurt_box)
		update_hp(99)
	pass


func update_hp (delta: int) -> void:
	hp = clampi(hp + delta,0,max_hp)
	pass


func make_invulnerable( _duration : float = 1.0) -> void:
	invulnerable = true
	hit_box.monitoring = false
	
	await get_tree().create_timer(_duration).timeout	
	invulnerable = false
	hit_box.monitoring = true
	pass
