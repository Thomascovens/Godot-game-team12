extends Node

#card game

var username = "player"
var character = "magician"
var loggedin = false
var victor = ""

#pregame

var current_player: Node2D = null

func set_player(player: Node2D) -> void:
	current_player = player

func get_player() -> Node2D:
	return current_player
