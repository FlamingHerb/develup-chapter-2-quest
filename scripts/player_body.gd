extends CharacterBody2D

@onready var player_sprite = $PlayerSprite
@onready var engine_fire_sprite = $PlayerSprite/EngineFire
@onready var hold_down_timer = $HoldDownTimer
@onready var player_orbit = $PlayerOrbit

var meteor_orbit_prefab = preload("res://scenes/player_orbit_follower.tscn")

const SPEED = 300.0
const ROTATION_SPEED = 2

func _ready() -> void:
	# Arm the timer
	hold_down_timer.start()
	hold_down_timer.paused = true
	hold_down_timer.wait_time = 1.0
	
func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_direction = Input.get_vector("player_left", "player_right", "player_up", "player_down")
	
	velocity = input_direction.normalized() * SPEED
	
	if velocity != Vector2(0, 0):
		player_sprite.rotation = velocity.angle() - (PI/2)
		engine_fire_sprite.visible = true
	else: 
		engine_fire_sprite.visible = false
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("player_reload"):
		hold_down_timer.paused = false
		print("Reloading")
		
	if Input.is_action_just_released("player_reload"):
		hold_down_timer.paused = true
		print("Not anymore")

func _orbit_spawn_after_timeout() -> void:
	var new_meteor = meteor_orbit_prefab.instantiate()
	
	player_orbit.add_child(new_meteor)
	
	print("Spawning")
