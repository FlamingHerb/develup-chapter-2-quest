extends CharacterBody2D

var player_reference: CharacterBody2D
var meteor_speed: float
var known_constant_velocity: Vector2
var bounced: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	known_constant_velocity = velocity

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		if not randf_range(0, 1) > 0.8: 
			velocity = velocity.bounce(collision_info.get_normal())
			#print("Boing")
			
		else:
			#print("Going towards player")
			#print("Collider velocity: ", collision_info.get_collider())
			_apply_force_towards_player()
			
		

func _apply_force_towards_player() -> void:
	#var dir_vec2player = position.direction_to(player_reference.position)
	#var target_velocity = dir_vec2player * 25 
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	var new_time = distance_to_player / known_constant_velocity.length()
	#print(new_time)
	#print(player_reference.global_position - global_position)
	velocity = ((player_reference.global_position - global_position) / new_time)
	#print(target_velocity)
