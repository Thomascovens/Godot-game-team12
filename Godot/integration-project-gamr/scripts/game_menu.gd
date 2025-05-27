extends Control
const HOST = "wss://itip-team12-backend-itip-project12.apps.okd.ucll.cloud/"
const DEFAULT_CHARACTER = "res://scenes/Characters/magician.tscn"

var websocket = WebSocketPeer.new()
var connected = false
var character_database_reference

var is_reconnecting = false
var reconnect_timer = 0.0
const RECONNECT_DELAY = 2.0
var reconnect_attempts = 0	
const MAX_RECONNECT_ATTEMPTS = 10

var current_character_scene


func _ready():
	character_database_reference = preload("res://scripts/CharacterDatabase.gd")
	$VBoxContainer/preGame.grab_focus() 
	create_character_node(DEFAULT_CHARACTER)
	get_username()
	connect_rfid()
	
	$VBoxContainer/Logout.visible = false
	$VBoxContainer/Logout.disabled = true
	
	if OS.has_feature("web"):
		$VBoxContainer/Login.visible = false
		$VBoxContainer/Login.disabled = true
		$VBoxContainer/cardGame.disabled = true
	else:
		$"VBoxContainer/preGame".disabled = true
		$"VBoxContainer/cardGame".disabled = true
		$VBoxContainer/Scan.disabled = true
		$VBoxContainer/Scan.visible = false


func get_username():
	var username = JavaScriptBridge.eval("localStorage.getItem('username');")
	print(username)
	if username:
		Global.username = username
	current_character_scene.get_node("username").text = Global.username

func create_character_node(path):
	if current_character_scene:
		remove_child(current_character_scene)
	var character_scene = load(path).instantiate()
	add_child(character_scene)
	character_scene.position = Vector2(-600,300)
	character_scene.scale = Vector2(2,2)
	current_character_scene = character_scene
	get_username()
	
	
func _on_game_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_card_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Card/main.tscn")

func _on_exit_to_login_pressed() -> void:
	get_tree().quit()

func connect_rfid():
	var err = websocket.connect_to_url(HOST + "character/switch",null)
	if err != OK:
		print("Unable to connect to server: ", err)
		start_reconnection()
		return
	reconnect_attempts = 0
	is_reconnecting = false

func start_reconnection():
	if reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
		print("Maximum reconnection attempts reached. Giving up.")
		return
	is_reconnecting = true
	reconnect_timer = RECONNECT_DELAY
	print("Will attempt to reconnect in ", RECONNECT_DELAY, " seconds...")

func _process(delta):
	if is_reconnecting:
		reconnect_timer -= delta
		if reconnect_timer <= 0:
			reconnect_attempts += 1
			print("Reconnection attempt ", reconnect_attempts, "/", MAX_RECONNECT_ATTEMPTS)
			connect_rfid()
			return
	websocket.poll()
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

func send_character_switch_request():
	var request = {"type": "switch_character_request"}
	var json_string = JSON.stringify(request)
	websocket.send_text(json_string)
	print("Sent character switch request")

func handle_message(message):
	print("Received message: ", message)
	var data = JSON.parse_string(message)
	if data != null and typeof(data) == TYPE_DICTIONARY:
		if data.has("type"):
			match data["type"]:
				"switch_character_pending":
					var statusMessage = data["message"]
					$StatusMessage.text = statusMessage
					
				"switch_character_success":
					var card_uid = data["cardUid"]
					change_character(card_uid)
				"error":
					print("Error: ", message["message"])
	else:
		print("failed to parse json")

func change_character(cardUid):
	var character_name = character_database_reference.CHARACTERS.find_key(cardUid)
	if character_name:
		create_character_node("res://scenes/Characters/"+ character_name +".tscn")
		Global.character = character_name
		$StatusMessage.text = ""
	else:
		$StatusMessage.text ="Card scanned is not valid"

func _scan_pressed() -> void:
	if websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		start_reconnection()
	send_character_switch_request()
	get_username()


	
