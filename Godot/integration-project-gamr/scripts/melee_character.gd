extends CharacterBody2D
signal hit(new_health: int)

@export var walk_speed := 180
@export var run_speed := 300
@export var max_health: int = 100
@export var attack_damage: int = 30
@export var attack_frame: int = 3  # het frame waarop de hitbox actief wordt

var health: int
var is_attacking := false
var is_invincible := false

@onready var hitbox := $Hitbox  # Area2D node
@onready var sprite := $AnimatedSprite2D

func _ready():
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.disabled = true

func _process(delta):
	if is_attacking:
		return

	var dir := Vector2.ZERO
	if Input.is_action_pressed("walk_right"): dir.x += 1
	if Input.is_action_pressed("walk_left"): dir.x -= 1
	if Input.is_action_pressed("walk_down"): dir.y += 1
	if Input.is_action_pressed("walk_up"): dir.y -= 1

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = dir * walk_speed
	else:
		velocity = Vector2.ZERO

	position += velocity * delta

	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		sprite.play("attack")

func _on_frame_changed():
	if sprite.animation == "attack" and sprite.frame == attack_frame:
		hitbox.disabled = false  # activeer hitbox net op het juiste frame

func _on_animation_finished():
	if sprite.animation == "attack":
		hitbox.disabled = true  # hitbox weer uit
		is_attacking = false

func _on_hitbox_body_entered(body):
	if not is_attacking:
		return
	if body.is_in_group("Mobs") and body.has_method("take_damage"):
		body.take_damage(attack_damage)

func take_damage(amount):
	if is_invincible:
		return
	health -= amount
	if health <= 0:
		die()

func die():
	velocity = Vector2.ZERO
	hide()
	queue_free()
