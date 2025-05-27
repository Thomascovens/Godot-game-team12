extends Node2D

const PORT = 1234
var server_address

func _on_address_field_text_changed() -> void:
	server_address = $AddressField.text
	

var peer = ENetMultiplayerPeer.new()

@export var player_field_scene: PackedScene
@export var opponent_field_scene: PackedScene

func _on_peer_connected(peer_id):
	var opponent_scene = opponent_field_scene.instantiate()
	add_child(opponent_scene)
	
	get_node("PlayerField").host_set_up()

func _on_host_button_pressed() -> void:
	disable_buttons()
	
	peer.create_server(PORT)
	
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	var player_scene = player_field_scene.instantiate()
	add_child(player_scene)


func _on_join_button_pressed() -> void:
	disable_buttons()
	if server_address:
		peer.create_client(server_address,PORT)
	else:
		peer.create_client("localhost",PORT)
	
	multiplayer.multiplayer_peer = peer
	
	var player_scene = player_field_scene.instantiate()
	add_child(player_scene)
	var opponent_scene = opponent_field_scene.instantiate()
	add_child(opponent_scene)
	
	player_scene.client_set_up()

func disable_buttons():
	$CanvasLayer/UI/VBoxContainer/HostButton.disabled = true
	$CanvasLayer/UI/VBoxContainer/JoinButton.disabled = true
	$CanvasLayer/UI/VBoxContainer/HostButton.visible = false
	$CanvasLayer/UI/VBoxContainer/JoinButton.visible = false
	$CanvasLayer/UI/VBoxContainer/AddressField.editable = false
	$CanvasLayer/UI/VBoxContainer/AddressField.visible = false
