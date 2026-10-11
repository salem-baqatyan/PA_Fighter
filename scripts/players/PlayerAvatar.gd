extends Node2D
class_name PlayerAvatar

var player_id := ""
var team := GameState.RED
var character := GameState.SWORD
var hp := 100.0
var max_hp := 100.0
var alive := true
var facing := Vector2.RIGHT
var attack_timer := 0.0
var combo_index := 0
var target_position := Vector2.ZERO
var abilities: AbilityComponent

func _ready() -> void:
	abilities = AbilityComponent.new()
	add_child(abilities)

func setup(id: String, data: Dictionary) -> void:
	player_id = id
	apply_data(data, true)

func apply_data(data: Dictionary, snap: bool = false) -> void:
	team = String(data.get("team", team))
	character = String(data.get("character", character))
	hp = float(data.get("hp", hp))
	max_hp = float(data.get("max_hp", max_hp))
	alive = bool(data.get("alive", alive))
	facing = Vector2(float(data.get("facing_x", facing.x)), float(data.get("facing_y", facing.y)))
	if facing.length_squared() < 0.01:
		facing = Vector2.RIGHT
	attack_timer = float(data.get("attack_timer", attack_timer))
	combo_index = int(data.get("combo_index", combo_index))
	target_position = Vector2(float(data.get("x", position.x)), float(data.get("y", position.y)))
	if snap:
		position = target_position
	queue_redraw()

func _process(delta: float) -> void:
	position = position.lerp(target_position, min(1.0, delta * 14.0))
	queue_redraw()

func _draw() -> void:
	var team_color := Color(0.95, 0.16, 0.16) if team == GameState.RED else Color(0.15, 0.45, 1.0)
	var config := CharacterCatalog.get_config(character)
	var body_color: Color = config.get("color", Color.WHITE)
	body_color = body_color.lerp(team_color, 0.32)
	if not alive:
		body_color = Color(0.25, 0.25, 0.28, 0.55)
	draw_circle(Vector2.ZERO, 25, Color(0.02, 0.03, 0.05, 0.5))
	draw_rect(Rect2(Vector2(-18, -20), Vector2(36, 40)), body_color)
	draw_rect(Rect2(Vector2(-16, -30), Vector2(32, 14)), team_color)
	var eye_dir := facing.normalized() * 16.0
	draw_circle(eye_dir + Vector2(0, -6), 4, Color.WHITE)
	if attack_timer > 0.0:
		var attack_range := float(config.get("attack_range", 96.0))
		var width := float(config.get("attack_width", 64.0))
		var dir := facing.normalized()
		if character == GameState.SWORD:
			draw_line(dir * 20.0, dir * attack_range, Color(1.0, 0.95, 0.55, 0.9), 10.0 + combo_index * 2.0)
			draw_arc(Vector2.ZERO, attack_range, dir.angle() - 0.32, dir.angle() + 0.32, 16, Color(1.0, 0.85, 0.36, 0.62), 5.0)
		else:
			draw_circle(dir * attack_range, width * 0.32, Color(1.0, 0.45, 0.25, 0.78))
			draw_circle(dir * (attack_range * 0.72), width * 0.25, Color(1.0, 0.72, 0.32, 0.62))
	var bar_width := 58.0
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -48), Vector2(bar_width, 6)), Color(0.08, 0.08, 0.08, 0.8))
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -48), Vector2(bar_width * clampf(hp / max_hp, 0.0, 1.0), 6)), Color(0.2, 1.0, 0.35))
