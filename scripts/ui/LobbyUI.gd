extends Control
class_name LobbyUI

signal create_room(server_url: String, character_id: String)
signal join_room(server_url: String, room_code: String, character_id: String)
signal character_changed(character_id: String)
signal ready_changed(is_ready: bool)
signal start_requested

var status_label: Label
var room_edit: LineEdit
var server_edit: LineEdit
var slots_label: Label
var ready_button: Button
var start_button: Button
var character_options: OptionButton
var message_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_top = 36
	root.offset_right = -28
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var title := Label.new()
	title.text = "PA-Fighter"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Two-player flying arena prototype"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	root.add_child(subtitle)

	server_edit = LineEdit.new()
	server_edit.placeholder_text = "Server URL"
	server_edit.text = NetworkManager.DEFAULT_URL
	server_edit.custom_minimum_size.y = 48
	root.add_child(server_edit)

	room_edit = LineEdit.new()
	room_edit.placeholder_text = "Room code"
	room_edit.custom_minimum_size.y = 48
	room_edit.max_length = 8
	root.add_child(room_edit)

	character_options = OptionButton.new()
	character_options.custom_minimum_size.y = 48
	character_options.add_item("Sword Fighter", 0)
	character_options.set_item_metadata(0, GameState.SWORD)
	character_options.add_item("Boxer", 1)
	character_options.set_item_metadata(1, GameState.BOXER)
	character_options.item_selected.connect(_on_character_selected)
	root.add_child(character_options)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)

	var create_button := Button.new()
	create_button.text = "Create Room"
	create_button.custom_minimum_size.y = 58
	create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_button.pressed.connect(func() -> void:
		create_room.emit(server_edit.text, _selected_character())
	)
	row.add_child(create_button)

	var join_button := Button.new()
	join_button.text = "Join Room"
	join_button.custom_minimum_size.y = 58
	join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_button.pressed.connect(func() -> void:
		join_room.emit(server_edit.text, room_edit.text, _selected_character())
	)
	row.add_child(join_button)

	ready_button = Button.new()
	ready_button.text = "Ready"
	ready_button.toggle_mode = true
	ready_button.custom_minimum_size.y = 58
	ready_button.pressed.connect(func() -> void:
		ready_changed.emit(ready_button.button_pressed)
	)
	root.add_child(ready_button)

	start_button = Button.new()
	start_button.text = "Start Match"
	start_button.custom_minimum_size.y = 58
	start_button.disabled = true
	start_button.pressed.connect(func() -> void: start_requested.emit())
	root.add_child(start_button)

	status_label = Label.new()
	status_label.text = "Connect to a server, then create or join a room."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)

	slots_label = Label.new()
	slots_label.text = "Player 1: empty\nPlayer 2: empty"
	slots_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(slots_label)

	message_label = Label.new()
	message_label.text = ""
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	root.add_child(message_label)

func set_status(text: String) -> void:
	status_label.text = text

func set_message(text: String) -> void:
	message_label.text = text

func set_room_code(code: String) -> void:
	room_edit.text = code

func update_lobby(players: Array, can_start: bool) -> void:
	var lines: Array[String] = []
	for i in range(2):
		if i < players.size():
			var p: Dictionary = players[i]
			var team := String(p.get("team", ""))
			var char_name := String(CharacterCatalog.get_config(String(p.get("character", GameState.SWORD))).get("display_name", "Fighter"))
			var is_ready := "READY" if bool(p.get("ready", false)) else "not ready"
			lines.append("Player %d: %s / %s / %s" % [i + 1, team.to_upper(), char_name, is_ready])
		else:
			lines.append("Player %d: empty" % [i + 1])
	slots_label.text = "\n".join(lines)
	start_button.disabled = not can_start

func _selected_character() -> String:
	return String(character_options.get_item_metadata(character_options.selected))

func _on_character_selected(_index: int) -> void:
	character_changed.emit(_selected_character())
