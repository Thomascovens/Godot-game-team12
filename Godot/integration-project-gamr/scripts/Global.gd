extends Node

var username = "player"
var opponent_username = ""
var character = "magician"
var loggedin = false
var victor = ""

var current_player: Node2D = null

func set_player(player: Node2D) -> void:
	current_player = player

func get_player() -> Node2D:
	return current_player
