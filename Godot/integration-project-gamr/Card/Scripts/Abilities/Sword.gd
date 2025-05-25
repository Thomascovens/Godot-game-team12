extends Node

const DAMAGE = 5
const HEALING = 3

func trigger_ability(player_field_manager, opponent_field_manager, battle_manager_reference,input_manager_reference, card_with_ability):
	input_manager_reference.inputs_disabled = true
	battle_manager_reference.enable_end_turn_button(false)
	
	if not battle_manager_reference.opponent_cards_on_battlefield.is_empty():
		var defending_card = battle_manager_reference.opponent_cards_on_battlefield.pick_random()
		
		defending_card.health = max(0,defending_card.health - DAMAGE)
		if defending_card.health == 0:
			battle_manager_reference.player_health += HEALING
			battle_manager_reference.destroy_card(defending_card, "Opponent")
	
	
	await battle_manager_reference.wait(1)
	battle_manager_reference.destroy_card(card_with_ability,"Player")
	input_manager_reference.inputs_disabled = false
	battle_manager_reference.enable_end_turn_button(true)
	

func trigger_opponent_ability(player_field_manager, opponent_field_manager, battle_manager_reference, card_with_ability):
	if not battle_manager_reference.player_cards_on_battlefield.is_empty():
		var defending_card = battle_manager_reference.player_cards_on_battlefield.pick_random()
		defending_card.health = max(0,defending_card.health - DAMAGE)
		if defending_card.health == 0:
			battle_manager_reference.opponent_health += HEALING
			battle_manager_reference.destroy_card(defending_card, "Player")

	battle_manager_reference.destroy_card(card_with_ability,"Opponent")
