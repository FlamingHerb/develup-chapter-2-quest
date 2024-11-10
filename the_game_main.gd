extends Node

@onready var player_ship = $PlayerBody

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_ship.position = Vector2(960, 540)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
