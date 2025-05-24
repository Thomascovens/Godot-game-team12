extends Node

const TORNADO_DAMAGE = 1
const NODE_NAME = "Character/AnimatedSprite2D"
const ANIMATION_NODE = "res://Card/Assets/Abilities/Tornado.tscn"

func trigger_ability(player_field_manager, opponent_field_manager, battle_manager_reference,input_manager_reference, card_with_ability):
	
	input_manager_reference.inputs_disabled = true
	battle_manager_reference.enable_end_turn_button(false)
	
	player_field_manager.get_node(NODE_NAME).play("attack1")
	var tornado = load(ANIMATION_NODE).instantiate()
	opponent_field_manager.add_child(tornado)
	tornado.position = opponent_field_manager.get_node("CardSlots/CardSlot10").position
	var tween = opponent_field_manager.create_tween()
	tween.tween_property(tornado, "position", opponent_field_manager.get_node("CardSlots/CardSlot8").position, 1)


	
	await battle_manager_reference.wait(1)
	player_field_manager.get_node(NODE_NAME).play("idle")
	var cards_to_destroy = []
	
	for card in battle_manager_reference.opponent_cards_on_battlefield:
		card.health = max(0, card.health - TORNADO_DAMAGE)
		card.get_node("Health").text = str(card.health)
		if card.health == 0:
			cards_to_destroy.append(card)
	await battle_manager_reference.wait(1)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			battle_manager_reference.destroy_card(card,"Opponent")
	battle_manager_reference.destroy_card(card_with_ability,"Player")
	opponent_field_manager.remove_child(tornado)
	await battle_manager_reference.wait(1)
	battle_manager_reference.enable_end_turn_button(true)
	input_manager_reference.inputs_disabled = true
	

func trigger_opponent_ability(player_field_manager, opponent_field_manager, battle_manager_reference, card_with_ability):
	await battle_manager_reference.wait(.3)
	var cards_to_destroy = []
	
	opponent_field_manager.get_node(NODE_NAME).play("attack1")
	var tornado = load(ANIMATION_NODE).instantiate()
	player_field_manager.add_child(tornado)
	tornado.position = player_field_manager.get_node("CardSlots/CardSlot10").position
	var tween = player_field_manager.create_tween()
	tween.tween_property(tornado, "position", player_field_manager.get_node("CardSlots/CardSlot8").position, 1)
	
	await battle_manager_reference.wait(1)
	opponent_field_manager.get_node(NODE_NAME).play("idle")
	
	for card in battle_manager_reference.player_cards_on_battlefield:
		card.health = max(0,card.health - TORNADO_DAMAGE)
		card.get_node("Health").text = str(card.health)
		if card.health == 0:
			cards_to_destroy.append(card)
	await battle_manager_reference.wait(1)
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			battle_manager_reference.destroy_card(card,"Player")
	battle_manager_reference.destroy_card(card_with_ability,"Opponent")
	
	player_field_manager.remove_child(tornado)
	await battle_manager_reference.wait(1)
