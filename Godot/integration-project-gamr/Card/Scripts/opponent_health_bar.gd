extends ProgressBar
func _process(delta: float) -> void:
	var battle_manager_reference = get_parent().get_parent().get_node("PlayerField/BattleManager")
	if battle_manager_reference:
		if battle_manager_reference.opponent_health:
			value = battle_manager_reference.opponent_health
	else:
		value = 0
