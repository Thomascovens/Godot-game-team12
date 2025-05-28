extends Node

const MODIFIER = .5

func trigger_ability(player_field_manager, opponent_field_manager, battle_manager_reference,input_manager_reference, card_with_ability):
	input_manager_reference.inputs_disabled = true
	battle_manager_reference.enable_end_turn_button(false)
	
	for card in battle_manager_reference.opponent_cards_on_battlefield:
		card.attack = ceili(card.attack * MODIFIER) 
	
	await battle_manager_reference.wait(1)
	battle_manager_reference.destroy_card(card_with_ability,"Player")
	input_manager_reference.inputs_disabled = false
	battle_manager_reference.enable_end_turn_button(true)
	

func trigger_opponent_ability(player_field_manager, opponent_field_manager, battle_manager_reference, card_with_ability):
	for card in battle_manager_reference.player_cards_on_battlefield:
		card.attack = ceili(card.attack * MODIFIER) 

	battle_manager_reference.destroy_card(card_with_ability,"Opponent")
