extends Node2D
class_name GameWorld

signal leave_lobby_requested

const ARENA_RECT := Rect2(-2300, -1100, 4600, 2200)

var network: NetworkManager
var local_id := ""
var players := {}
var towers := {}
var hud: MobileHUD
var camera: CameraController
var local_input := Vector2.ZERO
var dash_down := false
var _send_accum := 0.0

func initialize(net: NetworkManager, id: String) -> void:
	network = net
	local_id = id
	network.message_received.connect(_on_network_message)
	_build_world()

func _exit_tree() -> void:
	if network != null and network.message_received.is_connected(_on_network_message):
		network.message_received.disconnect(_on_network_message)

func _build_world() -> void:
	z_index = 0
	camera = CameraController.new()
	camera.arena_rect = ARENA_RECT
	add_child(camera)
	hud = MobileHUD.new()
	hud.attack_pressed.connect(func() -> void: network.send_message("attack"))
	hud.dash_pressed.connect(func(down: bool) -> void: dash_down = down)
	hud.destroy_pressed.connect(func() -> void: network.send_message("destroy_tower"))
	hud.rematch_pressed.connect(func() -> void: network.send_message("rematch"))
	hud.lobby_pressed.connect(func() -> void:
		network.send_message("return_lobby")
		leave_lobby_requested.emit()
	)
	hud.joystick_changed.connect(func(v: Vector2) -> void: local_input = v)
	add_child(hud)

func _process(delta: float) -> void:
	_send_accum += delta
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move := local_input
	if keyboard.length_squared() > move.length_squared():
		move = keyboard
	if Input.is_action_just_pressed("attack"):
		network.send_message("attack")
	if Input.is_action_pressed("dash"):
		dash_down = true
	elif Input.is_action_just_released("dash"):
		dash_down = false
	if Input.is_action_just_pressed("destroy_tower"):
		network.send_message("destroy_tower")
	if _send_accum >= 0.05:
		_send_accum = 0.0
		network.send_message("input", {"mx": move.x, "my": move.y, "dash": dash_down})

func _draw() -> void:
	draw_rect(ARENA_RECT, Color(0.05, 0.09, 0.12), true)
	draw_rect(ARENA_RECT, Color(0.25, 0.48, 0.58, 0.75), false, 6.0)
	draw_line(Vector2(ARENA_RECT.position.x, 0), Vector2(ARENA_RECT.end.x, 0), Color(0.4, 0.55, 0.52, 0.42), 18)
	draw_circle(Vector2.ZERO, 170, Color(0.12, 0.22, 0.22, 0.55))
	draw_rect(Rect2(Vector2(ARENA_RECT.position.x, -260), Vector2(330, 520)), Color(0.35, 0.05, 0.05, 0.45), true)
	draw_rect(Rect2(Vector2(ARENA_RECT.end.x - 330, -260), Vector2(330, 520)), Color(0.04, 0.12, 0.36, 0.45), true)
	for x in range(int(ARENA_RECT.position.x), int(ARENA_RECT.end.x), 240):
		draw_line(Vector2(x, ARENA_RECT.position.y), Vector2(x, ARENA_RECT.end.y), Color(1, 1, 1, 0.025), 2)
	for y in range(int(ARENA_RECT.position.y), int(ARENA_RECT.end.y), 240):
		draw_line(Vector2(ARENA_RECT.position.x, y), Vector2(ARENA_RECT.end.x, y), Color(1, 1, 1, 0.025), 2)

func _on_network_message(message: Dictionary) -> void:
	match String(message.get("type", "")):
		"snapshot":
			_apply_snapshot(message)
		"error":
			if hud != null:
				print("Server error: %s" % String(message.get("message", "")))

func _apply_snapshot(snapshot: Dictionary) -> void:
	var player_data: Dictionary = snapshot.get("players", {})
	for id in player_data.keys():
		var data: Dictionary = player_data[id]
		if not players.has(id):
			var avatar := PlayerAvatar.new()
			avatar.setup(String(id), data)
			players[id] = avatar
			add_child(avatar)
		else:
			players[id].apply_data(data)
	if players.has(local_id):
		camera.target = players[local_id]
	var tower_data: Dictionary = snapshot.get("towers", {})
	for team in tower_data.keys():
		for data in tower_data[team]:
			var id := String(data.get("id", ""))
			if id.is_empty():
				continue
			if not towers.has(id):
				var tower := TowerNode.new()
				tower.setup(data)
				towers[id] = tower
				add_child(tower)
			else:
				towers[id].apply_data(data)
	if hud != null:
		hud.apply_snapshot(snapshot, local_id)
