extends Node

@onready var player_ship = $PlayerBody
@onready var general_ui = $UIStuff
@onready var pause_screen = $UIStuff/PauseScreen

var known_high_score: int = 0
var currently_playing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.sfx_play("res://audio/bgm/juhani_title_screen.ogg")
	
	# Connect stuff
	
	player_ship.change_score_gui.connect(general_ui.change_score)
	player_ship.change_stamina_gui.connect(general_ui.change_stamina_bar)
	player_ship.change_bomb_value_gui.connect(general_ui.change_bomb_value)
	player_ship.change_next_bomb_gui.connect(general_ui.change_next_bomb_bar)
	#player_ship.reset_game.connect(general_ui.reset_game)
	player_ship.game_over_occured.connect(general_ui.game_over_occured)
	player_ship.game_over_occured.connect(_game_over_occured)
	player_ship.game_over_begun.connect(_game_over_occured)
	
	player_ship.close_call_detected.connect(general_ui._close_call_detected)
	player_ship.bomb_notification.connect(general_ui._bomb_notification)
	player_ship.game_over_begun.connect(general_ui._game_over_begun_notif)
	
	player_ship.send_high_score.connect(_save_high_score)
	
	general_ui.restart_game.connect(_reset_game)
	
	# Setting ship location
	
	player_ship.position = Vector2(960, 540)
	player_ship.visible = false
	
	# Adding in high score
	
	_load_high_score()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _unhandled_input(_event: InputEvent) -> void:
	# Pausing game
	if Input.is_action_just_pressed("player_pause"):
		if not currently_playing: return
		if get_tree().paused:
			pause_screen.visible = false
			AudioManager.resume_game()
			player_ship.game_got_resumed()
			general_ui.resume_game()
			get_tree().paused = false
		else:
			pause_screen.visible = true
			AudioManager.pause_game()
			player_ship.game_got_paused()
			general_ui.pause_game()
			get_tree().paused = true
	
	if Input.is_action_just_pressed("player_f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _reset_game() -> void:
	currently_playing = true
	player_ship.position = Vector2(960, 540)
	player_ship.reset_game()

func _game_over_occured() -> void:
	currently_playing = false

func _save_high_score(new_score: int) -> void:
	if new_score < known_high_score: return
		# Creates new ConfigFile object.
	var config = ConfigFile.new()
	
	# Stores some values.
	known_high_score = new_score
	config.set_value("Score", "high_score", known_high_score)

	# It's saving time! (No need to close, Godot already does the job for us)
	config.save("user://settings.cfg")
	
	general_ui.change_high_score(known_high_score)

func _load_high_score():
	# Creates new ConfigFile object
	var config = ConfigFile.new()
	
	# Loads settings with errors in mind.
	var err = config.load("user://settings.cfg")
	
	# If there's no settings, then make some.
	if err != OK:
		_save_high_score(200)
		return

	# If not, well, we're getting values. (No need to close, Godot does its job)
	known_high_score = config.get_value("Score", "high_score")
	
	general_ui.change_high_score(known_high_score)
	
	

#===============================================================================
# Change GUI stuff
#===============================================================================
