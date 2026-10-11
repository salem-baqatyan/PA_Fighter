extends Control
class_name VirtualJoystickControl

signal direction_changed(dir: Vector2)

@export var radius := 74.0
@export var knob_radius := 28.0

var value := Vector2.ZERO
var _dragging := false
var _touch_index := -1

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.2, radius * 2.2)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_dragging = true
			_update_value(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_dragging = false
			_set_value(Vector2.ZERO)
	if event is InputEventScreenDrag and event.index == _touch_index:
		_update_value(event.position)
	if event is InputEventMouseButton:
		_dragging = event.pressed
		if _dragging:
			_update_value(event.position)
		else:
			_set_value(Vector2.ZERO)
	if event is InputEventMouseMotion and _dragging:
		_update_value(event.position)

func _update_value(local_pos: Vector2) -> void:
	var center := size * 0.5
	var offset := local_pos - center
	_set_value(offset.limit_length(radius) / radius)

func _set_value(next_value: Vector2) -> void:
	value = next_value
	direction_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.04, 0.06, 0.09, 0.48))
	draw_arc(center, radius, 0.0, TAU, 56, Color(0.65, 0.85, 1.0, 0.55), 3.0)
	draw_circle(center + value * radius, knob_radius, Color(0.85, 0.95, 1.0, 0.82))
