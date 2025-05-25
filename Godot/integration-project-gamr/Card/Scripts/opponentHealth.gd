extends RichTextLabel

func _process(delta: float) -> void:
	var battleManagerReference = get_parent().get_node("PlayerField/BattleManager")
	if battleManagerReference != null:
		text = str(battleManagerReference.opponent_health)
