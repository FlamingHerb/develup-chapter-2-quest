extends CharacterBody2D

enum States {IDLE, MOVING, BOOSTING, SLOWDOWN}

# Change score
signal change_score_gui(value: int)

# Change stamina
signal change_stamina_gui(value: float)

# Emit 1 if adding, -1 if removing
signal change_bomb_value_gui(value: int)

# Change next bomb GUI
signal change_next_bomb_gui(value: int)

@onready var player_sprite = $PlayerSprite
@onready var engine_fire_sprite = $PlayerSprite/EngineFire
@onready var reload_animation = $ReloadAnim
@onready var hold_down_timer = $HoldDownTimer
@onready var player_orbit = $PlayerOrbit
@onready var asteroid_group = $"../AsteroidGroup"

@onready var reloading_color = Color(0.706, 0.396, 0.612)
@onready var full_reload_color = Color8(243, 170, 44)

@export var rate_of_fire: float = 0.4
@export var expected_meteor_speed: float = 0.2
@export var stamina_decay: float = 1

var meteor_orbit_prefab = preload("res://scenes/player_orbit_follower.tscn")
var actual_meteor_prefab = preload("res://scenes/meteor.tscn")
var can_fire = true
var reloading = false

# Remember, crucial.
var bombs: int = 2:
	set(value):
		bombs = value
		print("Current bomb count: ", bombs)

var current_state: States = States.IDLE:
	set(value):
		current_state = value
		match current_state:
			States.IDLE:
				print("Idle")
			States.MOVING:
				print("Moving")
			States.BOOSTING:
				print("Boosting")
			States.SLOWDOWN:
				print("Slowdown")


var stamina: float = 100:
	set(value):
		stamina = clampf(value, 0, 100)
		change_stamina_gui.emit(value)
		


# Placing it here to stop race condition.
var score: int = 0:
	get:
		return score
	set(value):
		score = value
		change_score_gui.emit(value)

var meteor_graphics = [
	preload("res://graphics/meteor/meteorbrown_big1.png"),
	preload("res://graphics/meteor/meteorbrown_big2.png"),
	preload("res://graphics/meteor/meteorbrown_big3.png"),
	preload("res://graphics/meteor/meteorbrown_big4.png"),
]

const SPEED = 200.0
const ROTATION_SPEED = 2


#===============================================================================
# Functions
#===============================================================================

func _ready() -> void:
	# Arm the timer
	hold_down_timer.paused = true
	
func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if stamina <= 0:
		_force_back_to_idle_moving()
	
	#region Movement
	if not reloading:
		var input_direction = Input.get_vector("player_left", "player_right", "player_up", "player_down")
		var actual_speed = SPEED
		if current_state == States.BOOSTING:
			actual_speed *= 2
			
		elif current_state == States.SLOWDOWN:
			actual_speed *= 0.5
			
		velocity = input_direction.normalized() * actual_speed
		_shoot_item_loop()
	else:
		velocity = Vector2.ZERO
	#endregion Movement
	
	#region Stamina
	# Stamina checking.
	if current_state == States.IDLE or current_state == States.MOVING:
		stamina += stamina_decay * 0.5
	elif current_state == States.BOOSTING and velocity != Vector2.ZERO:
		stamina -= stamina_decay 
	elif current_state == States.SLOWDOWN:
		stamina -= stamina_decay * 1.5
	#endregion Stamina
	
	if velocity != Vector2.ZERO:
		player_sprite.rotation = velocity.angle() - (PI/2)
		engine_fire_sprite.visible = true
	else:
		engine_fire_sprite.visible = false
	
	
	move_and_slide()

func _input(_event: InputEvent) -> void:
	if not (current_state == States.BOOSTING or current_state == States.SLOWDOWN):
		if Input.get_vector("player_left", "player_right", "player_up", "player_down") != Vector2.ZERO:
			current_state = States.MOVING
		else:
			current_state = States.IDLE
	
	if Input.is_action_just_pressed("player_reload"):
		hold_down_timer.paused = false
		reload_animation.visible = true
		reloading = true
		#print("Reloading")
		
	if Input.is_action_just_released("player_reload"):
		hold_down_timer.paused = true
		reload_animation.visible = false
		reloading = false
		#print("Not anymore")
	
	if Input.is_action_just_pressed("player_bomb"):
		if bombs != 0:
			_bomb_function(-1)
		else:
			print("Bombs not available.")

	#region Player Boosting
	if Input.is_action_just_pressed("player_boost") and stamina > 10:
		if current_state != States.SLOWDOWN:
			current_state = States.BOOSTING
		
	if Input.is_action_just_released("player_boost"):
		_force_back_to_idle_moving()
	#endregion Player Boosting
	
	#region Slowdown
	if Input.is_action_just_pressed("player_time_control") and stamina > 10:
		if current_state != States.BOOSTING:
			get_tree().call_group("Meteor", "change_speed_factor", 0.5)
			current_state = States.SLOWDOWN
			
	if Input.is_action_just_released("player_time_control"):
		#get_tree().call_group("Meteor", "change_speed_factor", 1)
		_force_back_to_idle_moving()
	#endregion Slowdown
	
func _orbit_spawn_after_timeout() -> void:
	# If children are already 10, don't bother reload.
	var child_count = float(player_orbit.get_child_count())
	if child_count > 9: return
	
	# Give score per each reload.
	score += 2
	
	var new_meteor = meteor_orbit_prefab.instantiate()
	new_meteor.meteor_sprite = meteor_graphics.pick_random()
	
	player_orbit.add_child(new_meteor)
	
	#print("Spawning. Current Count: ", child_count)
	
	if player_orbit.get_child_count() == 10:
		reload_animation.modulate = full_reload_color

# Reference: https://youtu.be/isA7P9ulBwE?si=SC0jZh4npf7n6H8E&t=576
func _shoot_item_loop() -> void:
	if Input.is_action_pressed("player_shoot") and can_fire == true:
		# Stops function if there are no available things to fire.
		if player_orbit.get_child_count() == 0: return
		
		# Disallow firing until done.
		can_fire = false
		
		var new_projectile = actual_meteor_prefab.instantiate()
		
		# Get randomly available meteor.
		var meteor_reference = player_orbit.get_child(randi() % player_orbit.get_child_count())
		
		# Position new projectile to meteor reference
		new_projectile.position = meteor_reference.get_global_position()
		# Set reference for projectile to know where player is
		new_projectile.player_reference = self
		
		new_projectile.speed_factor = 1.0 if current_state != States.SLOWDOWN else 0.5
		# Set meteor graphics to match with orbiting one.
		new_projectile.meteor_sprite = meteor_reference.meteor_sprite
		# Prepare it to where it should be firing towards.
		new_projectile.velocity = (new_projectile.position - position) / expected_meteor_speed
		
		# Connect signal to proper function spawner
		new_projectile.will_spawn_meteor.connect(_meteor_spawn_from_bounces)
		
		# Add new projectile
		asteroid_group.add_child(new_projectile)
		#  Remove meteor reference
		meteor_reference.queue_free()
		# Allow visual reloading to show up again.
		reload_animation.modulate = reloading_color
		
		# Add scoring after firing.
		score += 3
		
		# Wait for next firing sequence.
		await get_tree().create_timer(rate_of_fire).timeout
		can_fire = true

func _meteor_spawn_from_bounces(body_ref: CharacterBody2D) -> void:
	var new_projectile = actual_meteor_prefab.instantiate()
	# Position new projectile to meteor reference
	new_projectile.position = body_ref.get_global_position()
	# Set reference for projectile to know where player is
	new_projectile.player_reference = self
	new_projectile.speed_factor = body_ref.speed_factor
	# Set meteor graphics to match with orbiting one.
	new_projectile.meteor_sprite = body_ref.meteor_sprite
	# Prepare it to where it should be firing towards.
	if randf() > 0.5: new_projectile.velocity = body_ref.velocity.rotated(randf_range(-1, 0.1) * 2)
	else: new_projectile.velocity = body_ref.velocity.rotated(randf_range(0.1, 1) * 2)
		
	
	# Connect signal to proper function spawner
	new_projectile.will_spawn_meteor.connect(_meteor_spawn_from_bounces)
	
	# Add new projectile
	asteroid_group.add_child(new_projectile)

func _on_asteroid_group_child_entered_tree(_node: Node) -> void:
	#print(asteroid_group.get_child_count())
	
	change_next_bomb_gui.emit(asteroid_group.get_child_count())
	
	score += 1
	
	if asteroid_group.get_child_count() % 64 == 0 and asteroid_group.get_child_count() > 0:
		_bomb_function(1)

## 1 for add
## -1 for remove
func _bomb_function(value: int) -> void:
	match value:
		1:
			# Do not add if bombs are already at 2.
			if bombs > 1: 
				print("Bombs are full.")
				return
			bombs += 1
			change_bomb_value_gui.emit(1)
		-1:
			# Technically, will not run when bombs are 0. Done by input.
			bombs -= 1
			
			# Remove all the meteors currently in the game.
			get_tree().call_group("Meteor", "queue_free")
			change_next_bomb_gui.emit(0)
			
			# Tell the GUI to remove a bomb.
			change_bomb_value_gui.emit(-1)
			

func _force_back_to_idle_moving() -> void:
	get_tree().call_group("Meteor", "change_speed_factor", 1)
	if velocity != Vector2.ZERO:
		current_state = States.MOVING
	else: 
		current_state = States.IDLE
