extends Node

@onready var player_ship = $PlayerBody
@onready var general_ui = $UIStuff

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.sfx_play("res://audio/bgm/juhani_title_screen.ogg")
	
	player_ship.change_score_gui.connect(general_ui.change_score)
	player_ship.change_stamina_gui.connect(general_ui.change_stamina_bar)
	player_ship.change_bomb_value_gui.connect(general_ui.change_bomb_value)
	player_ship.change_next_bomb_gui.connect(general_ui.change_next_bomb_bar)
	#player_ship.reset_game.connect(general_ui.reset_game)
	player_ship.game_over_occured.connect(general_ui.game_over_occured)
	general_ui.restart_game.connect(_reset_game)
	
	player_ship.position = Vector2(960, 540)
	player_ship.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _reset_game() -> void:
	player_ship.position = Vector2(960, 540)
	player_ship.reset_game()

#===============================================================================
# Change GUI stuff
#===============================================================================
