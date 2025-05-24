extends Button


func _on_pressed() -> void:
	Global.username = ""
	Global.loggedin = false
	visible = false
	disabled = true
	$"../Login".visible = true
	$"../Login".disabled = false
	$"../preGame".disabled = true
	$"../cardGame".disabled = true
	$"../Scan".disabled = true
	$"../Scan".visible = false
