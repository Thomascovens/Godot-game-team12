extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var player_id := 1:
	set(id):
		player_id = id
