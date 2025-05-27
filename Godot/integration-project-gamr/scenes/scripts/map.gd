extends Node2D

func _ready():
	# Get the Area2D that holds all AnimatedSprite2D children
	var lake = $Lake_animations
	for sprite in lake.get_children():
		if sprite is AnimatedSprite2D:
			# Play the sprite's default animation (will loop if the animation resource is set to loop)
			sprite.play()
	var objects = $animated_objects
	for sprite in objects.get_children():
		if sprite is AnimatedSprite2D:
			# Play the sprite's default animation (will loop if the animation resource is set to loop)
			sprite.play()
