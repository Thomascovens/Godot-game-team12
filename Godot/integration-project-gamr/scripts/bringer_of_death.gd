extends RigidBody2D

signal hit(new_health: int)

@export var speed: float = 100.0
@export var max_health: int = 240
@export var shoot_cooldown: float = 3
@export var attack_range: float = 600

const AttackScene: PackedScene = preload("res://scenes/AttackBringerOfDeath.tscn")

var player: Node2D = null
var health: int
var is_dead: bool = false
var can_shoot: bool = true

@onready var sprite: AnimatedSprite2D              = $AnimatedSprite2D
@onready var muzzle: Marker2D                      = $shootlocation
@onready var collision_shape: CollisionShape2D     = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	health = max_health
	await get_tree().process_frame  # 🕒 Delay to ensure Global is set
	player = Global.get_player()

	if player == null:
		push_error("Ghost Wizard: No player found in Global.")
		return

	sprite.animation = "run"
	sprite.play()

	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	screen_notifier.connect("screen_exited", Callable(self, "_on_screen_exited"))

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		linear_velocity = Vector2.ZERO
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > attack_range:
		var dir = to_player.normalized()
		linear_velocity = dir * speed
	else:
		linear_velocity = Vector2.ZERO
		if can_shoot:
			_shoot_at(player.global_position)

func _shoot_at(_target_pos: Vector2) -> void:
	can_shoot = false

	sprite.sprite_frames.set_animation_loop("attack", false)
	sprite.animation = "attack"
	sprite.frame = 0
	sprite.play()

	# ❗️Spawn the attack effect above the player instead of firing a projectile
	if player != null:
		var attack := AttackScene.instantiate()
		var above_player := player.global_position + Vector2(0, -128)  # 64 pixels above
		attack.global_position = above_player
		get_tree().get_current_scene().add_child(attack)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func _on_animation_finished() -> void:
	match sprite.animation:
		"attack":
			sprite.animation = "run"
			sprite.play()
		"die":
			queue_free()

func take_damage(amount: int) -> void:
	print("Ghost Wizard taking damage:", amount)  # 🪵 Debug log
	if is_dead:
		return
	health = clamp(health - amount, 0, max_health)
	emit_signal("hit", health)
	if health == 0:
		die()

func die() -> void:
	is_dead = true
	linear_velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	sprite.sprite_frames.set_animation_loop("die", false)
	sprite.animation = "die"
	sprite.frame = 0
	sprite.play()
