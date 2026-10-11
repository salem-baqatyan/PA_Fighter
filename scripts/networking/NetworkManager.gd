extends Node
class_name NetworkManager

signal connected
signal disconnected(reason: String)
signal message_received(message: Dictionary)
signal status_changed(status: String)

const DEFAULT_URL := "ws://127.0.0.1:8090"

var socket := WebSocketPeer.new()
var _connected := false
var _url := DEFAULT_URL

func connect_to_server(url: String) -> void:
	_url = url.strip_edges()
	if _url.is_empty():
		_url = DEFAULT_URL
	close()
	socket = WebSocketPeer.new()
	status_changed.emit("Connecting to %s" % _url)
	var err := socket.connect_to_url(_url)
	if err != OK:
		status_changed.emit("Connection failed: %s" % error_string(err))
		disconnected.emit(error_string(err))

func close() -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.close()
	_connected = false

func _process(_delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _connected:
			_connected = true
			status_changed.emit("Connected")
			connected.emit()
		while socket.get_available_packet_count() > 0:
			var text := socket.get_packet().get_string_from_utf8()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				message_received.emit(parsed)
	elif state == WebSocketPeer.STATE_CLOSED and _connected:
		_connected = false
		var reason := "Disconnected"
		status_changed.emit(reason)
		disconnected.emit(reason)

func send_message(type: String, payload: Dictionary = {}) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		status_changed.emit("Not connected")
		return
	var packet := payload.duplicate(true)
	packet["type"] = type
	socket.send_text(JSON.stringify(packet))

func is_connected_to_server() -> bool:
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN
