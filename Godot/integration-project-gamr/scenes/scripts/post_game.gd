extends Control

func _ready() -> void:
	$Victory.text = Global.victor + " has won the game"


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_menu.tscn")
