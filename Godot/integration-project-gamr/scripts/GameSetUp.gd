extends Node2D

const STARTING_HEALTH = 20

func host_set_up():
	$PlayerHealth.text = str(STARTING_HEALTH)
	get_parent().get_node("OpponentField/OpponentHealth").text = str(STARTING_HEALTH)
	$BattleManager.player_health = STARTING_HEALTH
	$BattleManager.opponent_health = STARTING_HEALTH
	
	$CardSlots/CardSlot1.get_node("CardSlotImage").texture = ImageTexture.create_from_image(Image.load_from_file("res://Card/magicCardSlot.png"))
	
	get_parent().get_node("OpponentField/OpponentDeck").deck_size = $Deck.player_deck.size()
	get_parent().get_node("OpponentField/OpponentDeck/RichTextLabel").text = str($Deck.player_deck.size())
	
	var player_id = multiplayer.get_unique_id()
	
	await create_character_node("res://scenes/Characters/"+ Global.character +".tscn", player_id)
	rpc("create_character_node","res://scenes/Characters/"+ Global.character +".tscn", player_id)
	
	await $Deck.draw_initial_hand()
	
	$EndTurnButton.visible = true
	$EndTurnButton.disabled = false
	
	$InputManager.inputs_disabled = false

func client_set_up():
	$PlayerHealth.text = str(STARTING_HEALTH)
	get_parent().get_node("OpponentField/OpponentHealth").text = str(STARTING_HEALTH)
	$BattleManager.player_health = STARTING_HEALTH
	$BattleManager.opponent_health = STARTING_HEALTH
	
	
	
	get_parent().get_node("OpponentField/OpponentDeck").deck_size = 8
	get_parent().get_node("OpponentField/OpponentDeck/RichTextLabel").text = "8"
	
	var player_id = multiplayer.get_unique_id()
	await create_character_node("res://scenes/Characters/"+ Global.character +".tscn", player_id)
	await get_tree().create_timer(0.1).timeout
	rpc("create_character_node","res://scenes/Characters/"+ Global.character +".tscn", player_id)

	await $Deck.draw_initial_hand()

@rpc("any_peer")
func create_character_node(path, player_id):
	if multiplayer.get_unique_id() == player_id:
		var character_scene = load(path).instantiate()
		add_child(character_scene)
		character_scene.position = Vector2(350,750)
		character_scene.z_index = -4
		character_scene.scale = Vector2(2,2)
	else:
		var character_scene = load(path).instantiate()
		var opponentField = get_parent().get_node("OpponentField")
		opponentField.add_child(character_scene)
		character_scene.position = Vector2(1400,350)
		character_scene.z_index = -4
		character_scene.scale = Vector2(1.5,1.5)
		character_scene.get_node("AnimatedSprite2D").flip_h = true
