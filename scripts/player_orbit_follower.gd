extends PathFollow2D

var PROGRESS_SPEED: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PROGRESS_SPEED = randf_range(0.5, 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	progress_ratio += PROGRESS_SPEED * delta
	
