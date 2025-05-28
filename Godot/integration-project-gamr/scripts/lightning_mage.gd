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

	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	
	
	# ✅ Initialize the health bar on startup
	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.init_health(max_health)

func _process(delta):
	if is_attacking:
		return

	var dir := Vector2.ZERO

	if Input.is_action_pressed("walk_right"): dir.x += 1
	if Input.is_action_pressed("walk_left"):  dir.x -= 1
	if Input.is_action_pressed("walk_down"):  dir.y += 1
	if Input.is_action_pressed("walk_up"):    dir.y -= 1

	var is_running := Input.is_action_pressed("run")

	velocity = Vector2.ZERO
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		var speed = run_speed if is_running else walk_speed
		velocity = dir * speed

	var collision_result = move_and_collide(velocity * delta)
	if collision_result:
		var collider = collision_result.get_collider()
		if collider is RigidBody2D:
			var push_force = velocity.normalized() * 1000
			collider.apply_central_force(push_force)

	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		var dir_to_mouse = get_global_mouse_position() - global_position
		sprite.flip_h = dir_to_mouse.x < 0
		$Hitbox.rotation = dir_to_mouse.angle()
		sprite.play("attack")

	handle_animation()

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

	health = clamp(health - amount, 0, max_health)
	emit_signal("hit", health)

	# ✅ Update the HealthBar node
	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.health = health

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

	# ✅ Initialize the health bar here instead of _ready
	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.init_health(max_health)
