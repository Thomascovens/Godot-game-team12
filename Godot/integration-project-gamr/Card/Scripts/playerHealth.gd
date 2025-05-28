extends RichTextLabel

func _ready() -> void:
	text = str($"../BattleManager".player_health)

func _process(delta: float) -> void:
	text = str($"../BattleManager".player_health)
