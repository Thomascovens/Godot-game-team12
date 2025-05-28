extends Button

var websocket = WebSocketPeer.new()
var connected = false
var character_database_reference
signal character_selected(character_name)
signal draw_character_card(character_name)

func _ready():
	character_database_reference = preload("res://scripts/CharacterDatabase.gd")
	# Initialize WebSocket connection
	var error = websocket.connect_to_url("wss://itip-team12-backend-itip-project12.apps.okd.ucll.cloud/deck")
	if error != OK:
		print("Error connecting to WebSocket server: ", error)

func _process(delta):
	# Keep the connection alive
	websocket.poll()
	
	var state = websocket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not connected:
		connected = true
		print("Connected to WebSocket server")
	elif state == WebSocketPeer.STATE_CLOSED and connected:
		connected = false
		print("Disconnected from WebSocket server")
		# Try to reconnect
		websocket.connect_to_url("wss://itip-team12-backend-itip-project12.apps.okd.ucll.cloud/deck")

	while websocket.get_available_packet_count() > 0:
		var packet = websocket.get_packet()
		var message = packet.get_string_from_utf8()
		print("Received message: ", message)
		
		# Parse the JSON message
		var json = JSON.new()
		var error = json.parse(message)
		if error == OK:
			var response = json.get_data()
			if response is Dictionary and response.has("type"):
				if response["type"] == "scan_success" and response.has("cardUid"):
					var card_uid = response["cardUid"]
					print("Card scanned successfully: ", card_uid)
					
					# Look up character in database
					if character_database_reference.CHARACTERS.has(card_uid):
						var character_name = character_database_reference.CHARACTERS[card_uid]
						print("Character found: ", character_name)
						emit_signal("character_selected", character_name)
						
						# Draw a card from this character's deck
						emit_signal("draw_character_card", character_name)
					else:
						print("No character associated with card UID: ", card_uid)


func _on_pressed() -> void:
	if connected:
		print("Sending message to deck endpoint")
		var message = {"type": "scan_request"}
		var json_string = JSON.stringify(message)
		websocket.send_text(json_string)
	else:
		print("Not connected to WebSocket server, trying to reconnect...")
		websocket.connect_to_url("wss://itip-team12-backend-itip-project12.apps.okd.ucll.cloud/deck")
