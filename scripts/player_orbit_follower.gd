extends PathFollow2D

var progress_speed: float = 0
var meteor_sprite: CompressedTexture2D
@onready var meteor_sprite_2d = $MeteorSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	progress_speed = randf_range(0.5, 1)
	meteor_sprite_2d.texture = meteor_sprite

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	progress_ratio += progress_speed * delta
	
