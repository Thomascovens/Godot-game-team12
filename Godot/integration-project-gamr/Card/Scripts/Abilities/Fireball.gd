extends Node

const DAMAGE = 3

func trigger_ability(player_field_manager, opponent_field_manager, battle_manager_reference,input_manager_reference, card_with_ability):
	input_manager_reference.inputs_disabled = true
	battle_manager_reference.enable_end_turn_button(false)
	
	battle_manager_reference.opponent_health = max(0, battle_manager_reference.opponent_health - DAMAGE)
	opponent_field_manager.get_node("OpponentHealth").text = str(battle_manager_reference.opponent_health)
	await battle_manager_reference.wait(1)
	battle_manager_reference.destroy_card(card_with_ability,"Player")
	input_manager_reference.inputs_disabled = false
	battle_manager_reference.enable_end_turn_button(true)
	

func trigger_opponent_ability(player_field_manager, opponent_field_manager, battle_manager_reference, card_with_ability):
	
	battle_manager_reference.player_health = max(0, battle_manager_reference.player_health - DAMAGE)
	battle_manager_reference.destroy_card(card_with_ability,"Opponent")
