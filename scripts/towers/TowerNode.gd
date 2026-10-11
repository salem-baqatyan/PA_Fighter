extends Node2D
class_name TowerNode

var tower_id := ""
var team := GameState.RED
var index := 0
var chunks := 1
var max_chunks := 1
var active := false
var electric_radius := 210.0
var zap_timer := 0.0

func setup(data: Dictionary) -> void:
	tower_id = String(data.get("id", tower_id))
	team = String(data.get("team", team))
	index = int(data.get("index", index))
	position = Vector2(float(data.get("x", position.x)), float(data.get("y", position.y)))
	apply_data(data)

func apply_data(data: Dictionary) -> void:
	chunks = int(data.get("chunks", chunks))
	max_chunks = int(data.get("max_chunks", max_chunks))
	active = bool(data.get("active", active))
	electric_radius = float(data.get("electric_radius", electric_radius))
	queue_redraw()

func _process(delta: float) -> void:
	zap_timer += delta
	if zap_timer > 0.18:
		zap_timer = 0.0
		queue_redraw()

func _draw() -> void:
	var team_color := Color(0.9, 0.12, 0.15) if team == GameState.RED else Color(0.1, 0.42, 1.0)
	var base_color := team_color if chunks > 0 else Color(0.2, 0.2, 0.22)
	draw_circle(Vector2.ZERO, electric_radius, Color(team_color.r, team_color.g, team_color.b, 0.055 if active else 0.025))
	if active and chunks > 0:
		draw_arc(Vector2.ZERO, electric_radius, 0, TAU, 72, Color(0.45, 0.9, 1.0, 0.32), 4.0)
	draw_rect(Rect2(Vector2(-38, -72), Vector2(76, 144)), Color(0.04, 0.05, 0.07))
	draw_rect(Rect2(Vector2(-30, -64), Vector2(60, 128)), base_color)
	draw_colored_polygon(PackedVector2Array([Vector2(-44, -72), Vector2(0, -112), Vector2(44, -72)]), base_color)
	for i in range(max_chunks):
		var color := Color(1.0, 0.95, 0.35) if i < chunks else Color(0.12, 0.12, 0.12)
		draw_circle(Vector2(-22 + i * 22, 82), 8, color)
	if active and chunks > 0:
		for i in range(3):
			var a := randf() * TAU
			var b := a + randf_range(-0.7, 0.7)
			draw_line(Vector2.from_angle(a) * 48.0, Vector2.from_angle(b) * electric_radius * randf_range(0.35, 0.9), Color(0.6, 0.95, 1.0, 0.48), 2.0)
