extends CharacterBody2D

@export var walk_speed := 400
@export var run_speed := 700
@export var health := 100

@onready var sprite := $AnimatedSprite2D

var is_attacking := false
var attack_duration := 0.3
var attack_timer := 0.0

func _physics_process(delta):
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
		return

	var dir := Vector2.ZERO
	var is_running := false

	if Input.is_action_pressed("walk_right"):
		dir.x += 1
	if Input.is_action_pressed("walk_left"):
		dir.x -= 1
	if Input.is_action_pressed("walk_down"):
		dir.y += 1
	if Input.is_action_pressed("walk_up"):
		dir.y -= 1
		
	if Input.is_action_pressed("run_left") or Input.is_action_pressed("run_right") or Input.is_action_pressed("run_up") or Input.is_action_pressed("run_down"):
		is_running = true


	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		attack_timer = attack_duration
		sprite.play("attack")
		return

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = dir * (run_speed if is_running else walk_speed)
		sprite.flip_h = dir.x < 0
		sprite.play("run" if is_running else "walk")
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")

	move_and_slide()
