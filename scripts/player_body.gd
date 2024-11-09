extends CharacterBody2D

@onready var player_sprite = $PlayerSprite
@onready var engine_fire_sprite = $PlayerSprite/EngineFire
@onready var reload_animation = $ReloadAnim
@onready var hold_down_timer = $HoldDownTimer
@onready var player_orbit = $PlayerOrbit
@onready var asteroid_group = $"../AsteroidGroup"

@onready var reloading_color = Color(0.706, 0.396, 0.612)
@onready var full_reload_color = Color.RED

@export var rate_of_fire: float = 0.4
@export var expected_meteor_speed: float = 0.2

var meteor_orbit_prefab = preload("res://scenes/player_orbit_follower.tscn")
var actual_meteor_prefab = preload("res://scenes/meteor.tscn")
var can_fire = true

const SPEED = 300.0
const ROTATION_SPEED = 2

func _ready() -> void:
	# Arm the timer
	hold_down_timer.paused = true
	
func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#region Movement
	var input_direction = Input.get_vector("player_left", "player_right", "player_up", "player_down")
	
	velocity = input_direction.normalized() * SPEED
	
	if velocity != Vector2(0, 0):
		player_sprite.rotation = velocity.angle() - (PI/2)
		engine_fire_sprite.visible = true
	else: 
		engine_fire_sprite.visible = false
	#endregion Movement
	
	_shoot_item_loop()
	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("player_reload"):
		hold_down_timer.paused = false
		reload_animation.visible = true
		print("Reloading")
		
	if Input.is_action_just_released("player_reload"):
		hold_down_timer.paused = true
		reload_animation.visible = false
		print("Not anymore")

func _orbit_spawn_after_timeout() -> void:
	# If children are already 10, don't bother reload.
	if player_orbit.get_child_count() > 9: return
	
	var new_meteor = meteor_orbit_prefab.instantiate()
	
	player_orbit.add_child(new_meteor)
	
	print("Spawning. Current Count: ", player_orbit.get_child_count())
	
	if player_orbit.get_child_count() == 10:
		reload_animation.modulate = full_reload_color

# Reference: https://youtu.be/isA7P9ulBwE?si=SC0jZh4npf7n6H8E&t=576
func _shoot_item_loop() -> void:
	if Input.is_action_pressed("player_shoot") and can_fire == true:
		# Stops function if there are no available things to fire.
		if player_orbit.get_child_count() == 0: return
		
		can_fire = false
		var new_projectile = actual_meteor_prefab.instantiate()
		
		# Get first available meteor.
		var meteor_reference = player_orbit.get_child(0)						
		# Position new projectile to meteor reference
		new_projectile.position = meteor_reference.get_global_position()		
		
		# Prepare it to where it should be firing towards.
		new_projectile.linear_velocity = (new_projectile.position - position) / expected_meteor_speed
		
		# Add new projectile
		asteroid_group.add_child(new_projectile)
		#  Remove meteor reference
		meteor_reference.queue_free()
		# Allow visual reloading to show up again.
		reload_animation.modulate = reloading_color
		
		# Wait for next firing sequence.
		await get_tree().create_timer(rate_of_fire).timeout
		can_fire = true

func _on_asteroid_group_child_entered_tree(node: Node) -> void:
	if asteroid_group.get_child_count() == 64:
		print("Bomb available.")
