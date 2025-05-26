extends Node

const TORNADO_DAMAGE = 1

func trigger_ability(battle_manager_reference,input_manager_reference, card_with_ability):
	
	input_manager_reference.inputs_disabled = true
	battle_manager_reference.enable_end_turn_button(false)
	
	await battle_manager_reference.wait(3)
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
	await battle_manager_reference.wait(1)
	battle_manager_reference.enable_end_turn_button(true)
	input_manager_reference.inputs_disabled = true

func trigger_opponent_ability(battle_manager_reference, card_with_ability):
	await battle_manager_reference.wait(.3)
	var cards_to_destroy = []
	
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
	await battle_manager_reference.wait(1)
