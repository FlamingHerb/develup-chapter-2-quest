extends CharacterBody2D

@onready var ray_cast = $RayCast2D

var player_reference: CharacterBody2D
var speed_factor: float
var known_constant_velocity: Vector2
var rotation_speed: float = 2
var game_over_on: bool = false
var close_call_detected: bool = false

var bounces: int = 0
var can_spawn_meteor: bool = false

signal will_spawn_meteor(body_reference: CharacterBody2D)
signal player_hit()
signal close_call()

var meteor_sprite: CompressedTexture2D

var meteor_bounce_sfx = [
	preload("res://audio/sfx/meteor_bounce/sfx_sounds_impact1.wav"),
	preload("res://audio/sfx/meteor_bounce/sfx_sounds_impact3.wav"),
	preload("res://audio/sfx/meteor_bounce/sfx_sounds_impact4.wav"),
]

@onready var meteor_sprite_ref = $Sprite
@onready var speed_sprite = $SpeedSprite
@onready var collision_sprite = $CollisionSprite

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
		#print(collision_info.get_collider_shape())
		AudioManager.sfx_play(meteor_bounce_sfx.pick_random())
		
		if collision_info.get_collider().name == player_reference.name:
			# Player got hit
			velocity = Vector2.ZERO
			player_hit.emit()
			
			if game_over_on == true: queue_free()
			
			#collision_layer = 0
			#collision_sprite.visible = true
			#await get_tree().create_timer(1).timeout
			#queue_free()
				#
				
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
	
	# Only detect close calls if it's not a game over.
	if not game_over_on:
		ray_cast.target_position = player_reference.global_position - ray_cast.global_position
		if close_call_detected:
			if ray_cast.target_position.length() > 50.0:
				#print(ray_cast.target_position.length())
				close_call.emit()
				close_call_detected = false
		else:
			if ray_cast.target_position.length() < 18.0:
				#print(ray_cast.target_position.length())
				close_call_detected = true
	
	
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
	close_call_detected = false
	game_over_on = true
