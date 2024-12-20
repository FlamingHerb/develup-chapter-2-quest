extends CharacterBody2D

enum States {IDLE, MOVING, BOOSTING, SLOWDOWN, GAMEOVER}

# Change score
signal change_score_gui(value: int)

# Change stamina
signal change_stamina_gui(value: float)

# Emit 1 if adding, -1 if removing
signal change_bomb_value_gui(value: int)

# Change next bomb GUI
signal change_next_bomb_gui(value: int)

# Sending high score
signal send_high_score(value: int)

# Tell entire game to reset.
# signal reset_game()

signal game_over_occured()
signal close_call_detected()
signal bomb_notification(value: int)
signal game_over_begun()

@onready var player_sprite = $PlayerSprite
@onready var player_hitbox = $PlayerHitbox
@onready var engine_fire_sprite = $PlayerSprite/EngineFire
@onready var boost_fire_sprite = $PlayerSprite/BoostEngineFire
@onready var reload_animation = $ReloadAnim
@onready var hold_down_timer = $HoldDownTimer
@onready var game_over_timer = $GameOverTimer
@onready var player_orbit = $PlayerOrbit
@onready var asteroid_group = $"../AsteroidGroup"

@onready var animation_player = $"../AnimationPlayer"

@onready var reloading_color = Color(0.706, 0.396, 0.612)
@onready var full_reload_color = Color8(243, 170, 44)

@export var rate_of_fire: float = 0.4
@export var expected_meteor_speed: float = 0.2
@export var stamina_decay: float = 1

var meteor_orbit_prefab = preload("res://scenes/player_orbit_follower.tscn")
var actual_meteor_prefab = preload("res://scenes/meteor.tscn")
var can_fire: bool = true
var reloading: bool = false

# Remember, crucial.
var bombs: int = 2:
	set(value):
		bombs = value
		print("Current bomb count: ", bombs)
var bombs_detonated: int = 0:
	set(value):
		bombs_detonated = value
		print("Current difficulty: ", bombs_detonated)
var current_state: States = States.GAMEOVER:
	set(value):
		current_state = value
		#match current_state:
			#States.IDLE:
				#print("Idle")
			#States.MOVING:
				#print("Moving")
			#States.BOOSTING:
				#print("Boosting")
			#States.SLOWDOWN:
				#print("Slowdown")
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

# Sounds

var bomb_sfx = [
	preload("res://audio/sfx/bomb/sfx_exp_odd1.wav"),
	preload("res://audio/sfx/bomb/sfx_exp_odd3.wav"),
	preload("res://audio/sfx/bomb/sfx_exp_odd5.wav")
]

var bomb_error = preload("res://audio/sfx/bomb/sfx_sounds_error1.wav")

var stamina_low = preload("res://audio/sfx/player_ship/sfx_sound_shutdown1.wav")

var player_bomb_obtained = preload("res://audio/sfx/player_ship/sfx_sounds_powerup18.wav")

var bullet_warning_for_full_bomb = preload("res://audio/sfx/player_ship/sfx_lowhealth_alarmloop3.wav")

var shoot_sfx = [
	preload("res://audio/sfx/player_ship/sfx_wpn_laser8.wav"),
	preload("res://audio/sfx/player_ship/sfx_wpn_laser9.wav"),
	preload("res://audio/sfx/player_ship/sfx_wpn_laser10.wav")
]

var player_got_hit_sfx = [
	#preload("res://audio/sfx/player_ship/sfx_exp_shortest_hard1.wav"),
	#preload("res://audio/sfx/player_ship/sfx_exp_shortest_hard2.wav"),
	#preload("res://audio/sfx/player_ship/sfx_exp_shortest_hard3.wav")
	preload("res://audio/sfx/player_ship/sfx_exp_double1.wav"),
	preload("res://audio/sfx/player_ship/sfx_exp_double2.wav"),
	preload("res://audio/sfx/player_ship/sfx_exp_double3.wav")
]

var grabbing_meteors_sfx = [
	preload("res://audio/sfx/player_ship/sfx_sound_neutral1.wav"),
	preload("res://audio/sfx/player_ship/sfx_sound_neutral2.wav"),
	preload("res://audio/sfx/player_ship/sfx_sound_neutral6.wav")
]

var explosion_countdown_sfx = preload("res://audio/sfx/player_ship/countdown.ogg")

var explosion_sfx = preload("res://audio/sfx/player_ship/sfx_exp_long4.wav")

var space_ship_parts = [
	preload("res://graphics/spaceship_parts/beam0.png"),
	preload("res://graphics/spaceship_parts/cockpitRed_0.png"),
	preload("res://graphics/spaceship_parts/engine2.png"),
	preload("res://graphics/spaceship_parts/wingBlue_0.png")
]

const SPEED = 150.0
const ROTATION_SPEED = 2

#===============================================================================
# Functions
#===============================================================================

func _ready() -> void:
	# Arm the timer
	hold_down_timer.paused = true
	
func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if stamina <= 0:
		AudioManager.sfx_play(stamina_low)
		_force_back_to_idle_moving()
	
	#region Movement
	if not reloading:
		var input_direction = Input.get_vector("player_left", "player_right", "player_up", "player_down")
		var actual_speed = SPEED
		if current_state == States.BOOSTING:
			actual_speed *= 2
		elif current_state == States.SLOWDOWN:
			actual_speed *= 0.5
		if current_state == States.GAMEOVER:
			actual_speed *= 0.75
		
		velocity = input_direction.normalized() * actual_speed
		if not current_state == States.GAMEOVER: _shoot_item_loop()
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
		if current_state == States.BOOSTING: boost_fire_sprite.visible = true
		else: engine_fire_sprite.visible = true
	else:
		boost_fire_sprite.visible = false
		engine_fire_sprite.visible = false
	
	
	move_and_slide()

func _input(_event: InputEvent) -> void:
	# Disallow entry if it turns out player has died.
	if current_state == States.GAMEOVER: return
	
	if not (current_state == States.BOOSTING or current_state == States.SLOWDOWN):
		if Input.get_vector("player_left", "player_right", "player_up", "player_down") != Vector2.ZERO:
			current_state = States.MOVING
		else:
			current_state = States.IDLE
	
	if Input.is_action_just_pressed("player_reload"):
		AudioManager.play_reload_sfx()
		hold_down_timer.paused = false
		reload_animation.visible = true
		reloading = true
		
	if Input.is_action_just_released("player_reload"):
		AudioManager.stop_reload_sfx()
		hold_down_timer.paused = true
		reload_animation.visible = false
		reloading = false
		#print("Not anymore")
	
	if Input.is_action_just_pressed("player_bomb"):
		if bombs != 0:
			bombs_detonated += 1
			animation_player.play("explosion")
			_bomb_function(-1)
		else:
			AudioManager.sfx_play(bomb_error)
			print("Bombs not available.")

	#region Player Boosting
	if Input.is_action_just_pressed("player_boost") and stamina > 10:
		if current_state != States.SLOWDOWN:
			AudioManager.play_speedup_sfx()
			current_state = States.BOOSTING
		
	if Input.is_action_just_released("player_boost"):
		AudioManager.stop_speedup_sfx()
		_force_back_to_idle_moving()
	#endregion Player Boosting
	
	#region Slowdown
	if Input.is_action_just_pressed("player_time_control") and stamina > 10:
		if current_state != States.BOOSTING:
			AudioManager.play_slowdown_sfx()
			get_tree().call_group("Meteor", "change_speed_factor", 0.5)
			current_state = States.SLOWDOWN
			
	if Input.is_action_just_released("player_time_control"):
		AudioManager.stop_slowdown_sfx()
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
		
		# Fire ammo.
		AudioManager.sfx_play(shoot_sfx.pick_random())
		
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
		# Set trajectory speed according to bombs detonated. Expected true game over sequence around
		# 20+ bombs detonated.
		var speed_projection_difficulty = randf_range(expected_meteor_speed, expected_meteor_speed + 0.02) - (bombs_detonated * 0.005)
		# Prepare it to where it should be firing towards.
		new_projectile.velocity = (new_projectile.position - position) / speed_projection_difficulty
		#print(new_projectile.velocity.length())
		
		# Connect signal to proper function spawner
		new_projectile.will_spawn_meteor.connect(_meteor_spawn_from_bounces)
		new_projectile.player_hit.connect(_player_got_hit)
		new_projectile.close_call.connect(_close_call_detected)
		
		
		# Add new projectile
		asteroid_group.add_child(new_projectile)
		#  Remove meteor reference
		meteor_reference.queue_free()
		# Allow visual reloading to show up again.
		reload_animation.modulate = reloading_color
		
		# Add scoring after firing.
		score += 2
		
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
	# Projectile also inherits parents game_over_attribute as future-proofing.
	new_projectile.game_over_on = body_ref.game_over_on
	# Set meteor graphics to match with orbiting one.
	new_projectile.meteor_sprite = body_ref.meteor_sprite
	# Prepare it to where it should be firing towards.
	if randf() > 0.5: new_projectile.velocity = body_ref.velocity.rotated(randf_range(-1, 0.1) * 2)
	else: new_projectile.velocity = body_ref.velocity.rotated(randf_range(0.1, 1) * 2)
		
	
	# Connect signal to proper function spawner
	new_projectile.will_spawn_meteor.connect(_meteor_spawn_from_bounces)
	new_projectile.player_hit.connect(_player_got_hit)
	new_projectile.close_call.connect(_close_call_detected)

	
	# Add new projectile
	asteroid_group.add_child(new_projectile)

func _on_asteroid_group_child_entered_tree(_node: Node) -> void:
	#print(asteroid_group.get_child_count())
	# Will only add score WHEN player is alive!
	if not current_state == States.GAMEOVER: 
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
				AudioManager.sfx_play(player_bomb_obtained)
				bomb_notification.emit(-1)
				print("Bombs are full.")
				return
				
			AudioManager.sfx_play(player_bomb_obtained)
			bomb_notification.emit(1)
			bombs += 1
			change_bomb_value_gui.emit(1)
		-1:
			AudioManager.sfx_play(bomb_sfx.pick_random())
			# Technically, will not run when bombs are 0. Done by input.
			bombs -= 1
			
			# Remove all the meteors currently in the game.
			get_tree().call_group("Meteor", "queue_free")
			change_next_bomb_gui.emit(0)
			
			# Tell the GUI to remove a bomb.
			change_bomb_value_gui.emit(-1)
			
func _force_back_to_idle_moving() -> void:
	boost_fire_sprite.visible = false
	get_tree().call_group("Meteor", "change_speed_factor", 1)
	if velocity != Vector2.ZERO:
		current_state = States.MOVING
	else: 
		current_state = States.IDLE

func _player_got_hit() -> void:
	# Only occurs if meteor hits player again during GAMEOVER state.
	if current_state == States.GAMEOVER:
		AudioManager.sfx_play(grabbing_meteors_sfx.pick_random())
		print("Player grabs meteor.")
		score += 1
		return
		
	# Force player to go back before switching states.
	_force_back_to_idle_moving()
	
	
	# Sasme as if Input.is_action_just_released("player_reload"):
	hold_down_timer.paused = true
	reload_animation.visible = false
	reloading = false
	
	# Slows player down.
	
	current_state = States.GAMEOVER
	game_over_timer.start()
	
	# Tell meteors that behavior is not different.
	get_tree().call_group("Meteor", "game_over_sequence")
	
	game_over_begun.emit()
	AudioManager.sfx_play(player_got_hit_sfx.pick_random())
	AudioManager.game_over_effects_start()
	
	player_hitbox.shape.radius = 8
	
	AudioManager.sfx_play(explosion_countdown_sfx)
	
	print("Player hit! Game over!")

## When the game tells us that everything should be annihilated.
func _on_game_over_timer_timeout() -> void:
	#_reset_game()
	
	visible = false
	
	AudioManager.sfx_play(explosion_sfx)
	AudioManager.stop_level_bgm()
	AudioManager.game_over_effects_end()
	
	# Remove player collision.
	collision_layer = 0
	
	# Make spaceship parts
	_make_parts_gameover(space_ship_parts[0], Vector2(randi_range(-250, 250), randi_range(-250, 250)))
	_make_parts_gameover(space_ship_parts[1], Vector2(0, 250))
	_make_parts_gameover(space_ship_parts[2], Vector2(0, -250))
	_make_parts_gameover(space_ship_parts[3], Vector2(250, 0))
	_make_parts_gameover(space_ship_parts[3], Vector2(-250, 0))
	
	# Send high score.
	send_high_score.emit(score)
	
	await get_tree().create_timer(2).timeout
	
	get_tree().call_group("Meteor", "queue_free")
	
	
	game_over_occured.emit()
	
	
	
	print("Times out, time to die!")

func reset_game():
	# Change back shape to proper after gameover.
	player_hitbox.shape.radius = 4
	bombs = 2
	bombs_detonated = 0
	current_state = States.IDLE
	stamina = 100
	score = 0
	can_fire = true
	reloading = false
	
	# Return player collision.
	collision_layer = 3
	
	# Removes pre-existing player projectiles.
	get_tree().call_group("player_projectiles", "queue_free")
	
	visible = true
	#reset_game.emit()

func _close_call_detected():
	AudioManager.sfx_play(bullet_warning_for_full_bomb)
	score += 2
	close_call_detected.emit()
	

func _make_parts_gameover(wanted_texture: Texture2D, target_vector2d: Vector2) -> void:
	var new_space_ship_part = RigidBody2D.new()
	var space_ship_sprite = Sprite2D.new()
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = preload("res://themes/player_hitbox.tres")
	
	
	space_ship_sprite.texture = wanted_texture
	space_ship_sprite.scale = Vector2(0.25, 0.25)
	new_space_ship_part.position = position - Vector2(randi_range(-5, 5), randi_range(-5, 5))
	new_space_ship_part.linear_velocity = target_vector2d / 0.5
	new_space_ship_part.angular_velocity = 100
	new_space_ship_part.gravity_scale = 0
	new_space_ship_part.collision_layer = 0
	new_space_ship_part.add_to_group("Meteor")
	
	new_space_ship_part.add_child(space_ship_sprite)
	new_space_ship_part.add_child(collision_shape)
	
	asteroid_group.add_child(new_space_ship_part)
	
func game_got_paused() -> void:
	pass
	
func game_got_resumed() -> void:
	pass
