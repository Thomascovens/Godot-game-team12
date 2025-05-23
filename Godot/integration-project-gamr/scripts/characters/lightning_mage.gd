extends CharacterBody2D
signal hit(new_health: int)

@export var walk_speed := 180
@export var run_speed := 320
@export var max_health: int = 120
@export var attack_damage: int = 40
@export var attack_frame: int = 5  # pas dit aan op basis van sprite

var health: int
var is_attacking := false
var is_invincible := false

@onready var sprite := $AnimatedSprite2D
@onready var hitbox := $Hitbox
@onready var hitbox_shape := $Hitbox/CollisionShape2D
@onready var collision := $CollisionShape2D

func _ready():
	health = max_health
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox_shape.disabled = true
	hitbox.monitoring = false

func _process(delta):
	if is_attacking:
		return

	var dir := Vector2.ZERO
	var is_running := false

	if Input.is_action_pressed("walk_right"): dir.x += 1
	if Input.is_action_pressed("walk_left"): dir.x -= 1
	if Input.is_action_pressed("walk_down"): dir.y += 1
	if Input.is_action_pressed("walk_up"): dir.y -= 1

	if Input.is_action_pressed("run_right"): dir.x += 1; is_running = true
	if Input.is_action_pressed("run_left"): dir.x -= 1; is_running = true
	if Input.is_action_pressed("run_down"): dir.y += 1; is_running = true
	if Input.is_action_pressed("run_up"): dir.y -= 1; is_running = true

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = dir * (run_speed if is_running else walk_speed)
	else:
		velocity = Vector2.ZERO

	position += velocity * delta
	handle_animation()

	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		var aim_direction = (get_global_mouse_position() - global_position).normalized()
		sprite.flip_h = aim_direction.x < 0
		hitbox.rotation = aim_direction.angle()
		sprite.play("attack")

func handle_animation():
	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		sprite.animation = "run" if velocity.length() > walk_speed else "walk"
	else:
		sprite.animation = "idle"

	sprite.flip_h = velocity.x < 0
	sprite.play()

func _on_frame_changed():
	if sprite.animation == "attack" and sprite.frame == attack_frame:
		hitbox_shape.disabled = false
		hitbox.monitoring = true

func _on_animation_finished():
	if sprite.animation == "attack":
		hitbox_shape.disabled = true
		hitbox.monitoring = false
		is_attacking = false
		sprite.play("idle")
	elif sprite.animation == "death":
		queue_free()

func _on_hitbox_body_entered(body):
	if not is_attacking or hitbox_shape.disabled:
		return
	if body.is_in_group("Mobs") and body.has_method("take_damage"):
		body.take_damage(attack_damage)

func take_damage(amount: int):
	if is_invincible:
		return

	health -= amount
	emit_signal("hit", health)

	if health <= 0:
		die()
	else:
		is_invincible = true
		sprite.modulate.a = 0.3
		await get_tree().create_timer(1.5).timeout
		is_invincible = false
		sprite.modulate.a = 1.0

func die():
	is_attacking = false
	is_invincible = true
	velocity = Vector2.ZERO
	collision.set_deferred("disabled", true)
	sprite.sprite_frames.set_animation_loop("death", false)
	sprite.play("death")

func start(pos: Vector2):
	position = pos
	show()
	collision.disabled = false
