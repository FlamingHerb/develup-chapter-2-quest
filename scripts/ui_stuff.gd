extends CanvasLayer

#signal change_score(value: int)
#signal change_stamina(value: int)
#signal change_bomb_count(value: int)
#signal change_next_bomb_count(value: int)

signal restart_game()

@onready var score_text = $RightSide/ScorePanel/ScoreText
@onready var stamina_bar = $RightSide/StaminaPanel/StaminaBar
@onready var bomb_container = $RightSide/BombPanel/BombContainer
@onready var next_bomb_bar = $RightSide/NextBombPanel/NextBombBar
@onready var overcharge_bar = $RightSide/NextBombPanel/OverChargeBar

@onready var bomb_panel = $RightSide/BombPanel
@onready var next_bomb_panel = $RightSide/NextBombPanel

@onready var start_game_panel = $StartGame
@onready var restart_panel = $RestartPanel

var texture_rect_ref = preload("res://scenes/bomb_graphic.tscn")

var next_bomb_grey_pref = preload("res://themes/next_bomb_grey.tres")
var next_bomb_blue_pref = preload("res://themes/next_bomb_blue.tres")
var next_bomb_gold_pref = preload("res://themes/next_bomb_yellow.tres")

var bomb_panel_red = preload("res://themes/bomb_panel_red.tres")
var bomb_panel_blue = preload("res://themes/blue_panel_corner.tres")
var bomb_panel_yellow = preload("res://themes/bomb_panel_yellow.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_bomb_value(1)
	change_bomb_value(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## Adding is done in player body. Not here. Only UI.
func change_score(value: int) -> void:
	score_text.text = "%0*d" % [7, value]

func change_stamina_bar(value: float) -> void:
	stamina_bar.value = clampf(value, stamina_bar.min_value, stamina_bar.max_value)

## 1 is adding, -1 if removing
func change_bomb_value(value: int) -> void:
	match value:
		1:
			_add_bomb_graphic()
		-1:
			# Bomb container? Delete your first child. NOW.
			bomb_container.get_child(0).queue_free()
	
	#var child_count = await bomb_container.get_child_count()
	#print("Current children: ", child_count)
	#if child_count == 2:
		#bomb_panel.add_theme_stylebox_override("panel", bomb_panel_yellow)
	#elif child_count == 1: 
		#bomb_panel.add_theme_stylebox_override("panel", bomb_panel_blue)
	#elif child_count == 0:
		#bomb_panel.add_theme_stylebox_override("panel", bomb_panel_red)

func _add_bomb_graphic() -> void:
	var new_bomb_graphic = texture_rect_ref.instantiate()
	bomb_container.add_child(new_bomb_graphic)

func change_next_bomb_bar(value: int) -> void:
	#print(value)
	if value < 64:
		next_bomb_panel.add_theme_stylebox_override("panel", next_bomb_grey_pref)
	elif value >= 64 and value < 128:
		next_bomb_panel.add_theme_stylebox_override("panel", next_bomb_blue_pref)
	elif value >= 128:
		next_bomb_panel.add_theme_stylebox_override("panel", next_bomb_gold_pref)
	else:
		next_bomb_panel.add_theme_stylebox_override("panel", next_bomb_grey_pref)
		
	next_bomb_bar.value = clampi(value, next_bomb_bar.min_value, next_bomb_bar.max_value)
	overcharge_bar.value = clampi(value - 64, overcharge_bar.min_value, overcharge_bar.max_value)

func game_over_occured() -> void:
	restart_panel.visible = true

func reset_game() -> void:
	change_score(0)
	change_stamina_bar(100)
	
	get_tree().call_group("bomb_graphic", "queue_free")
	change_bomb_value(1)
	change_bomb_value(1)
	
	change_next_bomb_bar(0)
	
	print("Resetting UI.")

func _on_restart_button_pressed() -> void:
	restart_panel.visible = false
	_reset_functions()

func _on_new_game_button_pressed() -> void:
	start_game_panel.visible = false
	_reset_functions()

func _reset_functions() -> void:
	AudioManager.sfx_stop_all()
	AudioManager.play_level_bgm()
	restart_game.emit()
	reset_game()

func pause_game() -> void:
	pass
	
func resume_game() -> void:
	pass
	
