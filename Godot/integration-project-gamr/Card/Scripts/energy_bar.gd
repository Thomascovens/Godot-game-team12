extends ProgressBar
func _process(delta: float) -> void:
	value = $"../BattleManager".energy
