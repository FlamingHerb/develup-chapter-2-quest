extends CanvasLayer

#signal change_score(value: int)
#signal change_stamina(value: int)
#signal change_bomb_count(value: int)
#signal change_next_bomb_count(value: int)

@onready var score_text = $RightSide/ScorePanel/ScoreText
@onready var stamina_bar = $RightSide/StaminaPanel/StaminaBar
@onready var bomb_container = $RightSide/BombPanel/BombContainer
@onready var next_bomb_bar = $RightSide/NextBombPanel/NextBombBar
@onready var overcharge_bar = $RightSide/NextBombPanel/OverChargeBar

var texture_rect_ref = preload("res://scenes/bomb_graphic.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_add_bomb_graphic()
	_add_bomb_graphic()

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

func _add_bomb_graphic() -> void:
	var new_bomb_graphic = texture_rect_ref.instantiate()
	bomb_container.add_child(new_bomb_graphic)

func change_next_bomb_bar(value: int) -> void:
	#print(value)
	next_bomb_bar.value = clampi(value, next_bomb_bar.min_value, next_bomb_bar.max_value)
	overcharge_bar.value = clampi(value - 64, overcharge_bar.min_value, overcharge_bar.max_value)

func reset_game() -> void:
	print("Resetting UI.")
