extends CharacterBody2D

var player_reference: CharacterBody2D
var speed_factor: float
var known_constant_velocity: Vector2
var rotation_speed: float = 2
var game_over_on: bool = false

var bounces: int = 0
var can_spawn_meteor: bool = false
signal will_spawn_meteor(body_reference: CharacterBody2D)
signal player_hit()

var meteor_sprite: CompressedTexture2D

var meteor_bounce_sfx = [
	preload("res://audio/sfx/meteor_bounce/sfx_sounds_impact1.wav"),
	preload("res://audio/sfx/meteor_bounce/sfx_sounds_impact3.wav"),
	preload("res://audio/sfx/meteor_bounce/sfx_sounds_impact4.wav"),
]

@onready var meteor_sprite_ref = $Sprite
@onready var speed_sprite = $SpeedSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	known_constant_velocity = velocity
	#print(velocity.length())
	_rotate_speed_sprite()
	meteor_sprite_ref.texture = meteor_sprite
	
func _physics_process(delta: float) -> void:
	meteor_sprite_ref.rotation += rotation_speed * delta * speed_factor
	var collision_info = move_and_collide(velocity * delta * speed_factor)
	if collision_info:
		AudioManager.sfx_play(meteor_bounce_sfx.pick_random())
		
		if collision_info.get_collider().name == player_reference.name:
			player_hit.emit()
			if game_over_on == true: queue_free()
		
		# Decide whether it will bounce towards player or not.
		if not randf_range(0, 1) > 0.69: 
			velocity = velocity.bounce(collision_info.get_normal())
		else:
			if game_over_on == false: _apply_force_towards_player()
			else: velocity = velocity.bounce(collision_info.get_normal())
		
		# If it can spawn a meteor, call function and reset bounce counter.
		if can_spawn_meteor == true:
			_spawn_another_meteor()
			meteor_sprite_ref.modulate = Color.WHITE
		else:
			if not bounces >= 3: bounces += 1
		
		# Decide if it will spawn another meteor.
		if bounces >= 3:
			if randf_range(0, 1) > 0.75:
				can_spawn_meteor = true
				meteor_sprite_ref.modulate = Color(1.5, 0, 0)
		
	_rotate_speed_sprite()
		
func _apply_force_towards_player() -> void:
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	var new_time = distance_to_player / known_constant_velocity.length()
	
	velocity = ((player_reference.global_position - global_position) / new_time)

func _spawn_another_meteor() -> void:
	# Emit back to game main.
	will_spawn_meteor.emit(self)
	
	# Meteor will not spawn anymore.
	can_spawn_meteor = false

func _rotate_speed_sprite() -> void:
	speed_sprite.rotation = velocity.angle() - (PI/2)

func change_speed_factor(value: float) -> void:
	speed_factor = value

func game_over_sequence() -> void:
	change_speed_factor(0.5)
	game_over_on = true
