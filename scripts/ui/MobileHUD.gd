extends CanvasLayer
class_name MobileHUD

signal attack_pressed
signal dash_pressed(is_down: bool)
signal destroy_pressed
signal rematch_pressed
signal lobby_pressed
signal joystick_changed(value: Vector2)

var red_hp: ProgressBar
var blue_hp: ProgressBar
var dash_bar: ProgressBar
var tower_label: Label
var destroy_button: Button
var victory_panel: PanelContainer
var victory_label: Label
var joystick: VirtualJoystick
var dash_button: Button

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top := HBoxContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 12
	top.offset_top = 12
	top.offset_right = -12
	top.add_theme_constant_override("separation", 16)
	root.add_child(top)

	red_hp = _make_hp_panel(top, "RED", Color(0.95, 0.22, 0.20))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	blue_hp = _make_hp_panel(top, "BLUE", Color(0.18, 0.55, 1.0))

	tower_label = Label.new()
	tower_label.anchor_left = 0.5
	tower_label.anchor_right = 0.5
	tower_label.offset_left = -175
	tower_label.offset_right = 175
	tower_label.offset_top = 76
	tower_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tower_label.add_theme_font_size_override("font_size", 14)
	root.add_child(tower_label)

	dash_bar = ProgressBar.new()
	dash_bar.anchor_left = 0.54
	dash_bar.anchor_right = 0.96
	dash_bar.anchor_top = 1.0
	dash_bar.anchor_bottom = 1.0
	dash_bar.offset_top = -172
	dash_bar.offset_bottom = -150
	dash_bar.max_value = 100
	dash_bar.value = 100
	root.add_child(dash_bar)

	joystick = get_node_or_null("VirtualJoystick") as VirtualJoystick
	if joystick == null:
		joystick = VirtualJoystick.new()
		root.add_child(joystick)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 22
	joystick.offset_top = -190
	joystick.offset_right = 190
	joystick.offset_bottom = -22
	if joystick and joystick.has_signal("direction_changed"):
		joystick.connect("direction_changed", Callable(self, "_on_joystick_direction_changed"))
	elif joystick:
		pass

	var attack_button := Button.new()
	attack_button.text = "ATTACK"
	attack_button.anchor_left = 1.0
	attack_button.anchor_right = 1.0
	attack_button.anchor_top = 1.0
	attack_button.anchor_bottom = 1.0
	attack_button.offset_left = -138
	attack_button.offset_top = -122
	attack_button.offset_right = -24
	attack_button.offset_bottom = -20
	attack_button.pressed.connect(func() -> void: attack_pressed.emit())
	root.add_child(attack_button)

	dash_button = Button.new()
	dash_button.text = "DASH"
	dash_button.anchor_left = 1.0
	dash_button.anchor_right = 1.0
	dash_button.anchor_top = 1.0
	dash_button.anchor_bottom = 1.0
	dash_button.offset_left = -254
	dash_button.offset_top = -112
	dash_button.offset_right = -150
	dash_button.offset_bottom = -28
	dash_button.button_down.connect(func() -> void: dash_pressed.emit(true))
	dash_button.button_up.connect(func() -> void: dash_pressed.emit(false))
	root.add_child(dash_button)

	destroy_button = Button.new()
	destroy_button.text = "DESTROY TOWER"
	destroy_button.visible = false
	destroy_button.anchor_left = 0.5
	destroy_button.anchor_right = 0.5
	destroy_button.anchor_top = 1.0
	destroy_button.anchor_bottom = 1.0
	destroy_button.offset_left = -118
	destroy_button.offset_top = -250
	destroy_button.offset_right = 118
	destroy_button.offset_bottom = -196
	destroy_button.pressed.connect(func() -> void: destroy_pressed.emit())
	root.add_child(destroy_button)

	victory_panel = PanelContainer.new()
	victory_panel.visible = false
	victory_panel.anchor_left = 0.08
	victory_panel.anchor_right = 0.92
	victory_panel.anchor_top = 0.32
	victory_panel.anchor_bottom = 0.68
	root.add_child(victory_panel)
	var victory_box := VBoxContainer.new()
	victory_box.alignment = BoxContainer.ALIGNMENT_CENTER
	victory_box.add_theme_constant_override("separation", 16)
	victory_panel.add_child(victory_box)
	victory_label = Label.new()
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.add_theme_font_size_override("font_size", 34)
	victory_box.add_child(victory_label)
	var rematch := Button.new()
	rematch.text = "Rematch"
	rematch.custom_minimum_size.y = 52
	rematch.pressed.connect(func() -> void: rematch_pressed.emit())
	victory_box.add_child(rematch)
	var lobby := Button.new()
	lobby.text = "Return to Lobby"
	lobby.custom_minimum_size.y = 52
	lobby.pressed.connect(func() -> void: lobby_pressed.emit())
	victory_box.add_child(lobby)

func _make_hp_panel(parent: Control, label_text: String, color: Color) -> ProgressBar:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(178, 48)
	parent.add_child(box)
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", color)
	box.add_child(label)
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	box.add_child(bar)
	return bar

func _on_joystick_direction_changed(direction: Vector2) -> void:
	joystick_changed.emit(direction)

func apply_snapshot(snapshot: Dictionary, local_id: String) -> void:
	var players: Dictionary = snapshot.get("players", {})
	for id in players.keys():
		var p: Dictionary = players[id]
		var hp_bar := red_hp if String(p.get("team", "")) == GameState.RED else blue_hp
		hp_bar.max_value = float(p.get("max_hp", 100))
		hp_bar.value = float(p.get("hp", 100))
		if String(id) == local_id:
			dash_bar.value = float(p.get("dash_energy", 0))
			destroy_button.visible = bool(p.get("destroy_charge", false)) and String(snapshot.get("phase", "")) == "playing"
			_update_dash_feedback(dash_bar.value, bool(p.get("dashing", false)))
	_update_tower_label(snapshot.get("towers", {}), snapshot.get("active_tower", {}))
	if String(snapshot.get("phase", "")) == "victory":
		show_victory(String(snapshot.get("winner", "")))
	else:
		victory_panel.visible = false

func show_victory(winner: String) -> void:
	victory_panel.visible = true
	victory_label.text = "%s TEAM WINS" % winner.to_upper()

func _update_dash_feedback(energy: float, active: bool) -> void:
	if energy <= 5:
		dash_button.modulate = Color(0.55, 0.55, 0.55)
	elif energy < 25:
		dash_button.modulate = Color(1.0, 0.35, 0.25)
	elif active:
		dash_button.modulate = Color(0.45, 0.9, 1.0)
	else:
		dash_button.modulate = Color.WHITE

func _update_tower_label(towers: Dictionary, active: Dictionary) -> void:
	var parts: Array[String] = []
	for team in [GameState.RED, GameState.BLUE]:
		var tower_list: Array = towers.get(team, [])
		var tower_parts: Array[String] = []
		for i in range(tower_list.size()):
			var tower: Dictionary = tower_list[i]
			var chunks: int = int(tower.get("chunks", 0))
			var max_chunks: int = int(tower.get("max_chunks", chunks))
			var dots := ""
			for c in range(max_chunks):
				dots += "●" if c < chunks else "○"
			var prefix := ">"
			if String(active.get(team, "")) != String(tower.get("id", "")):
				prefix = ""
			tower_parts.append("%sT%d:%s" % [prefix, i + 1, dots])
		parts.append("%s %s" % [team.to_upper(), "  ".join(tower_parts)])
	tower_label.text = "\n".join(parts)
