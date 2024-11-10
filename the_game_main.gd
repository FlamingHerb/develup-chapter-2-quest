extends Node

@onready var player_ship = $PlayerBody
@onready var general_ui = $UIStuff

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_ship.position = Vector2(960, 540)
	player_ship.change_score_gui.connect(general_ui.change_score)
	player_ship.change_stamina_gui.connect(general_ui.change_stamina_bar)
	player_ship.change_bomb_value_gui.connect(general_ui.change_bomb_value)
	player_ship.change_next_bomb_gui.connect(general_ui.change_next_bomb_bar)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#===============================================================================
# Change GUI stuff
#===============================================================================
