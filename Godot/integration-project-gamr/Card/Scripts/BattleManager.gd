extends Node

var STARTING_HEALTH = 10
var BATTLE_POS_OFFSET = 5

var battle_timer
var empty_card_slots=[]
var opponent_cards_on_battlefield=[]
var player_cards_on_battlefield = []
var player_cards_that_attacked_this_turn = []
var is_opponents_turn = false
var player_is_attacking = false


var player_health
var opponent_health

func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_card_slots.append($"../CardSlots/CardSlot11")
	empty_card_slots.append($"../CardSlots/CardSlot12")
	empty_card_slots.append($"../CardSlots/CardSlot13")
	empty_card_slots.append($"../CardSlots/CardSlot14")
	empty_card_slots.append($"../CardSlots/CardSlot15")
	empty_card_slots.append($"../CardSlots/CardSlot16")
	empty_card_slots.append($"../CardSlots/CardSlot17")
	empty_card_slots.append($"../CardSlots/CardSlot18")
	empty_card_slots.append($"../CardSlots/CardSlot19")
	empty_card_slots.append($"../CardSlots/CardSlot20")
	
	player_health = STARTING_HEALTH
	$"../PlayerHealth".text = str(player_health)
	opponent_health = STARTING_HEALTH
	$"../OpponentHealth".text = str(opponent_health)

func _on_end_turn_button_pressed() -> void:
	is_opponents_turn = true
	player_cards_that_attacked_this_turn = []
	$"../CardManager".unselect_selected_monster()
	opponent_turn()
	
func opponent_turn() -> void:
	await wait(1)
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false

	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
	
	if empty_card_slots.size() != 0:
		await try_play_card_with_highest_atk()
	
	if opponent_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			if player_cards_on_battlefield.size() != 0:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				await attack(card, card_to_attack,"Opponent")
			else:
				await direct_attack(card, "Opponent")
	
	end_opponent_turn()

func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
		player_is_attacking = true
		new_pos_y = 0
		player_cards_that_attacked_this_turn.append(attacking_card)
	var new_pos = Vector2(attacking_card.position.x,new_pos_y)
	
	attacking_card.z_index = 5
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, 0.2)
	await wait(0.15)
	
	if attacker == "Opponent":
		update_player_health(- attacking_card.attack)
	else:
		update_opponent_health(- attacking_card.attack)
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, 0.2)
	
	attacking_card.z_index = 0
	await wait(1)
	if attacker == "Player":
		player_is_attacking = false
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true

func attack(attacking_card, defending_card, attacker):
	if attacker == "Player":
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
		player_is_attacking = true
		$"../CardManager".selected_monster = null
		player_cards_that_attacked_this_turn.append(attacking_card)
	
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, 0.2)
	await wait(0.5)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, 0.2)
	
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	
	await wait(1.0)
	attacking_card.z_index = 0
	
	var card_was_destroyed = false
	
	if attacking_card.health == 0:
		destroy_card(attacking_card, attacker)
		card_was_destroyed = true
	if defending_card.health == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")

		else:
			destroy_card(defending_card, "Player")
		card_was_destroyed = true	
	
	if card_was_destroyed:
		await wait(1)
	
	if attacker == "Player":
		player_is_attacking = false
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true

func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_monster
	if attacking_card:
		if defending_card in opponent_cards_on_battlefield:
			if !player_is_attacking:
				$"../CardManager".selected_monster = null
				attack(attacking_card,defending_card, "Player")
		

func destroy_card(card, card_owner):
	var new_pos
	if card_owner == "Player":
		card.defeated = true
		new_pos = $"../PlayerDiscard".position
		card.get_node("Area2D/CollisionShape2D").disabled = true
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
		card.card_slot_card_is_in.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_pos = $"../OpponentDiscard".position
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)
	
	card.card_slot_card_is_in.card_in_slot = false
	card.card_slot_card_is_in = null
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, 0.2)


func try_play_card_with_highest_atk():

	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
	var random_empty_card_slot = empty_card_slots.pick_random()
	empty_card_slots.erase(random_empty_card_slot)
	
	var current_card_with_highest_atk = opponent_hand[0]
	for card in opponent_hand:
		if card.attack > current_card_with_highest_atk.attack:
			current_card_with_highest_atk = card
	
	var tween = get_tree().create_tween()
	tween.tween_property(current_card_with_highest_atk, "position", random_empty_card_slot.position, 0.2)
	current_card_with_highest_atk.get_node("AnimationPlayer").play("card_flip")
	
	$"../OpponentHand".remove_card_from_hand(current_card_with_highest_atk)
	current_card_with_highest_atk.card_slot_card_is_in = random_empty_card_slot
	opponent_cards_on_battlefield.append(current_card_with_highest_atk)
	await wait(1)

func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func update_player_health(x):
	player_health = max(0, player_health + x)
	$"../PlayerHealth".text = str(player_health)

func update_opponent_health(x):
	opponent_health = max(0,opponent_health + x)
	$"../OpponentHealth".text = str(opponent_health)

func end_opponent_turn():
	$"../Deck".reset_draw()
	is_opponents_turn = false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
	
	
	
