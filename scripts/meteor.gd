extends CharacterBody2D

var player_reference: CharacterBody2D
var meteor_speed: float
var known_constant_velocity: Vector2
var bounced: bool = false
var rotation_speed: float = 2

var meteor_sprite: CompressedTexture2D
@onready var meteor_sprite_ref =$Sprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	known_constant_velocity = velocity
	meteor_sprite_ref.texture = meteor_sprite
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	rotation += rotation_speed * delta
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		#print("Collider velocity: ", collision_info.get_collider().name)
		if not randf_range(0, 1) > 0.8: 
			velocity = velocity.bounce(collision_info.get_normal())
		else:
			_apply_force_towards_player()
			
		
func _apply_force_towards_player() -> void:
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	var new_time = distance_to_player / known_constant_velocity.length()
	
	velocity = ((player_reference.global_position - global_position) / new_time)
