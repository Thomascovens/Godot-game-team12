extends Node

var STARTING_HEALTH = 10
var BATTLE_POS_OFFSET = 5

var battle_timer
var opponent_cards_on_battlefield=[]
var player_cards_on_battlefield = []
var player_cards_that_attacked_this_turn = []
var player_is_attacking = false
var energy = 5


var player_health
var opponent_health

func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	

	#player_health = STARTING_HEALTH
	#$"../PlayerHealth".text = str(player_health)
	#opponent_health = STARTING_HEALTH
	#$"../OpponentHealth".text = str(opponent_health)



func _on_end_turn_button_pressed() -> void:
	enable_end_turn_button(false)
	$"../InputManager".inputs_disabled = true
	player_cards_that_attacked_this_turn = []
	$"../CardManager".unselect_selected_monster()
	rpc("change_turn")

@rpc("any_peer")
func change_turn():
	$"../Deck".reset_draw()
	enable_end_turn_button(true)
	$"../InputManager".inputs_disabled = false
	energy = 5

func reduce_energy(cost):
	energy -= cost


func direct_attack(attacking_card):
	$"../InputManager".inputs_disabled = true
	enable_end_turn_button(false)
	player_cards_that_attacked_this_turn.append(attacking_card)	
	
	var player_id = multiplayer.get_unique_id()

	rpc("direct_attack_here_and_replicate_client_opponent",player_id,str(attacking_card.name))
	await direct_attack_here_and_replicate_client_opponent(player_id,str(attacking_card.name))
	
	
	enable_end_turn_button(true)
	$"../InputManager".inputs_disabled = false

@rpc("any_peer")
func direct_attack_here_and_replicate_client_opponent(player_id,attacking_card_name):
	
	var attacking_card
	var attack_pos_y
	var new_pos
	
	if multiplayer.get_unique_id() == player_id:
		attacking_card = $"../CardManager".get_node(attacking_card_name)
		attack_pos_y = 0
		new_pos = get_parent().get_parent().get_node("OpponentField/Character").position
	else:
		attacking_card = get_parent().get_parent().get_node("OpponentField/CardManager/"+attacking_card_name)
		new_pos = $"..".get_node("Character").position
	
	attacking_card.z_index = 5
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, 0.2)
	await wait(0.15)
	var victor
	if multiplayer.get_unique_id() == player_id:
		opponent_health = max(0,opponent_health - attacking_card.attack)
		get_parent().get_parent().get_node("OpponentField/OpponentHealth").text = str(opponent_health)
		if opponent_health == 0 :
			$"../InputManager".inputs_disabled = true
			$"../EndTurnButton".disabled = true
			victor = Global.username
	else:
		player_health = max(0, player_health - attacking_card.attack)
		$"../PlayerHealth".text = str(player_health)
		if player_health == 0:
			victor = get_parent().get_parent().get_node("OpponentField/Character/username").text
			print(get_parent().get_parent().get_node("OpponentField/Character/username").text)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, 0.2)
	
	attacking_card.z_index = 0
	await wait(0.15)
	if victor:
		print(victor)
		Global.victor = victor
		get_tree().change_scene_to_file("res://Card/Scenes/PostGame.tscn")
	
func get_shield_cards(battlefield_cards):
	var shield_cards = []
	for card in battlefield_cards:
		if card.defence:
			shield_cards.append(card)
	return shield_cards


func attack(attacking_card, defending_card):
	$"../InputManager".inputs_disabled = true
	enable_end_turn_button(false)
	$"../CardManager".selected_monster = null
	player_cards_that_attacked_this_turn.append(attacking_card)
	
	var player_id = multiplayer.get_unique_id()

	var shield_cards = get_shield_cards(opponent_cards_on_battlefield)
	if shield_cards.size() > 0 and !attacking_card.focus:
		shield_cards.shuffle()
		var shield_card = shield_cards[0]
		rpc("attack_here_and_replicate_client_opponent",player_id,str(attacking_card.name),str(shield_card.name))
		await attack_here_and_replicate_client_opponent(player_id,str(attacking_card.name),str(shield_card.name))
		enable_end_turn_button(true)
		$"../InputManager".inputs_disabled = false
		return
	rpc("attack_here_and_replicate_client_opponent",player_id,str(attacking_card.name),str(defending_card.name))
	await attack_here_and_replicate_client_opponent(player_id,str(attacking_card.name),str(defending_card.name))
	
	enable_end_turn_button(true)
	$"../InputManager".inputs_disabled = false

@rpc("any_peer")
func attack_here_and_replicate_client_opponent(player_id,attacking_card_name, defending_card_name):
	var attacking_card
	var defending_card
	var y_offset
	
	if multiplayer.get_unique_id() == player_id:
		attacking_card = $"../CardManager".get_node(attacking_card_name)
		defending_card = get_parent().get_parent().get_node("OpponentField/CardManager/"+defending_card_name)
		y_offset = BATTLE_POS_OFFSET
		if attacking_card.ability_script:
			var cards_to_destroy = attacking_card.ability_script.trigger_ability(opponent_cards_on_battlefield)
			for card in cards_to_destroy:
				destroy_card(card, "Opponent")
	else:
		attacking_card = get_parent().get_parent().get_node("OpponentField/CardManager/"+attacking_card_name)
		defending_card = $"../CardManager".get_node(defending_card_name)
		y_offset = -BATTLE_POS_OFFSET
		if attacking_card.ability_script:
			var cards_to_destroy = attacking_card.ability_script.trigger_ability(player_cards_on_battlefield)
			for card in cards_to_destroy:
				destroy_card(card, "Player")
	
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + y_offset)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, 0.1)
	await wait(0.1)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, 0.1)
	
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	attacking_card.z_index = 0
	
	var card_was_destroyed = false
	
	if attacking_card.health == 0:
		if multiplayer.get_unique_id() == player_id:
			destroy_card(attacking_card, "Player")
		else:
			destroy_card(attacking_card, "Opponent")
		card_was_destroyed = true
	if defending_card.health == 0:
		
		if multiplayer.get_unique_id() == player_id:
			if !defending_card.defeated:
				destroy_card(defending_card, "Opponent")
		else:
			if !defending_card.defeated:
				destroy_card(defending_card, "Player")
		card_was_destroyed = true	
	
	if card_was_destroyed:
		await wait(0.15)

func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_monster
	if attacking_card:
		if defending_card in opponent_cards_on_battlefield:
			if !player_is_attacking:
				$"../CardManager".selected_monster = null
				attack(attacking_card,defending_card)
		

func get_rage_cards(cards_on_field):
	var rage_cards = []
	for card in cards_on_field:
		if card.rage:
			rage_cards.append(card)
	return rage_cards

@rpc("any_peer")
func empower_rage_cards(player_id, card_owner):

	var rage_cards_to_empower = []
	if multiplayer.get_unique_id() == player_id:
		if card_owner == "Player":
			rage_cards_to_empower = get_rage_cards(player_cards_on_battlefield)
		else:
			rage_cards_to_empower = get_rage_cards(opponent_cards_on_battlefield)

	if rage_cards_to_empower:
		for card in rage_cards_to_empower:
			card.attack += 1
			card.health += 2
			card.get_node("Attack").text = str(card.attack)
			card.get_node("Health").text = str(card.health)

func destroy_card(card, card_owner):
	var new_pos
	var player_id = multiplayer.get_unique_id()
	
	empower_rage_cards(player_id, card_owner)
	rpc("empower_rage_cards",player_id, card_owner)
	
	if card_owner == "Player":
		
		new_pos = $"../PlayerDiscard".position
		card.get_node("Area2D/CollisionShape2D").disabled = true
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
		card.card_slot_card_is_in.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_pos = get_parent().get_parent().get_node("OpponentField/OpponentDiscard").position
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)
	
	card.defeated = true
	card.card_slot_card_is_in.card_in_slot = false
	card.card_slot_card_is_in = null
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, 0.2)


func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout


	
func enable_end_turn_button(is_enabled):
	if is_enabled:
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
	else:
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
	
