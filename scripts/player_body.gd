extends CharacterBody2D


const SPEED = 300.0
const ROTATION_SPEED = 2


func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_direction = Input.get_vector("player_left", "player_right", "player_up", "player_down")
	
	velocity = input_direction.normalized() * SPEED
	
	if velocity != Vector2(0, 0):
		rotation = velocity.angle() - (PI/2)
	
	move_and_slide()
