extends CharacterBody2D

var player_reference: CharacterBody2D
var meteor_speed: float
var known_constant_velocity: Vector2
var rotation_speed: float = 2

var bounces: int = 0
var can_spawn_meteor: bool = false
signal will_spawn_meteor(body_reference: CharacterBody2D)

var meteor_sprite: CompressedTexture2D
@onready var meteor_sprite_ref = $Sprite
@onready var speed_sprite = $SpeedSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	known_constant_velocity = velocity
	_rotate_speed_sprite()
	meteor_sprite_ref.texture = meteor_sprite
	
func _physics_process(delta: float) -> void:
	meteor_sprite_ref.rotation += rotation_speed * delta
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		
		# Decide whether it will bounce towards player or not.
		if not randf_range(0, 1) > 0.8: 
			velocity = velocity.bounce(collision_info.get_normal())
		else:
			_apply_force_towards_player()
		
		
		
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
