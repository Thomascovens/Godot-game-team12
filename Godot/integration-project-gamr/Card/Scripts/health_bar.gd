extends ProgressBar
func _process(delta: float) -> void:
	if $"../BattleManager".player_health:
		value = $"../BattleManager".player_health
	else:
		value = 0
