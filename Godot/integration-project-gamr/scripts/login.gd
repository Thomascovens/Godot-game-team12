extends Button

const HOST = "wss://itip-team12-backend-itip-project12.apps.okd.ucll.cloud/"
var websocket = WebSocketPeer.new()

func _ready() -> void:
	print("Connecting to WebSocket...")
	var err = websocket.connect_to_url(HOST + "users/godotlogin", null)
	if err != OK:
		push_error("WebSocket connection failed: %s" % err)

func handle_message(message):
	var data = JSON.parse_string(message)
	if data.type == "pending_card":
		$"../../StatusMessage".text = data.payload.message
	elif data.type == "login_success":
		var username = data.payload.username
		Global.username = username
		Global.loggedin = true
		$"../../StatusMessage".text = data.payload.message
		$"../../Username".text = Global.username
		visible = false
		disabled = true
		$"../Logout".visible = true
		$"../Logout".disabled = false
		$"../preGame".disabled = false
		$"../cardGame".disabled = false
		$"../Scan".visible = true
		$"../Scan".disabled = false
	elif data.type == "login_failed":
		$"../../StatusMessage".text = data.payload.message

func _process(delta):
	var state = websocket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while websocket.get_available_packet_count():
			var message = websocket.get_packet().get_string_from_utf8()
			print("Got data from server: ", message)
			handle_message(message)
	# WebSocketPeer.STATE_CLOSING means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = websocket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing.
	websocket.poll() # Required to process events

func _on_pressed() -> void:
	websocket.send_text("Login Requested")

# Signal handlers
func _on_connection_established(protocol: String) -> void:
	print("✅ Connected to WebSocket server")

func _on_connection_closed(was_clean: bool) -> void:
	print("❌ WebSocket connection closed. Clean: %s" % was_clean)

func _on_connection_error() -> void:
	print("⚠️ WebSocket connection error")

func _on_data_received() -> void:
	var packet = websocket.get_peer(1).get_packet().get_string_from_utf8()
	print("📩 Received data: %s" % packet)
