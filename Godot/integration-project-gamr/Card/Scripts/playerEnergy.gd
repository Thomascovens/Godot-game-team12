extends RichTextLabel

func _ready() -> void:
	text = str($"../BattleManager".energy)

func _process(delta: float) -> void:
	text = str($"../BattleManager".energy)
