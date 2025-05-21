extends Control

func _ready():
	$VBoxContainer/preGame.grab_focus() 

func _on_game_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_exit_to_login_pressed() -> void:
	get_tree().quit()
