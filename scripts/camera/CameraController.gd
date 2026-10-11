extends Camera2D
class_name CameraController

@export var arena_rect := Rect2(-2300, -1100, 4600, 2200)
@export var look_ahead := Vector2(180, 130)
@export var smoothing := 5.0

var target: Node2D
var target_facing := Vector2.RIGHT

func _ready() -> void:
	enabled = true
	position_smoothing_enabled = false

func _process(delta: float) -> void:
	if target == null:
		return
	if target is PlayerAvatar:
		target_facing = (target as PlayerAvatar).facing
	var ahead := Vector2(signf(target_facing.x) * look_ahead.x, signf(target_facing.y) * look_ahead.y)
	if absf(target_facing.x) < 0.1:
		ahead.x = 0
	if absf(target_facing.y) < 0.1:
		ahead.y = 0
	var desired := target.global_position + ahead
	var viewport_size := get_viewport_rect().size / zoom
	var min_pos := arena_rect.position + viewport_size * 0.5
	var max_pos := arena_rect.position + arena_rect.size - viewport_size * 0.5
	desired.x = clampf(desired.x, min_pos.x, max_pos.x)
	desired.y = clampf(desired.y, min_pos.y, max_pos.y)
	global_position = global_position.lerp(desired, min(1.0, delta * smoothing))
