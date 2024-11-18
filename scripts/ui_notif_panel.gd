extends Panel

@onready var timer = $Timer
@onready var bomb_available = $BombAvailable
@onready var bombs_full = $BombsFull
@onready var close_call = $CloseCall
@onready var game_over_sequence = $GameOverSequence


var notif_type: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1 for available bomb, 2 for full bombs, 3 for close call, 4 for game over notif
	match notif_type:
		1:
			bomb_available.visible = true
		2:
			bombs_full.visible = true
		3:
			close_call.visible = true
		4:
			game_over_sequence.visible = true
	
	if game_over_sequence.visible:
		timer.start(7.0)
	else:
		timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_timer_timeout() -> void:
	queue_free()
