extends CharacterBody2D
signal hit(new_health: int)

@export var walk_speed := 200
@export var run_speed := 400
@export var max_health: int = 100
@export var projectile_scene: PackedScene = preload("res://scenes/Characters/projectiles/lightning_ball.tscn")
@export var projectile_offset: Vector2 = Vector2(0, -30)

var health: int
var is_attacking: bool = false
var is_invincible: bool = false

func _ready():
	health = max_health

	if not $AnimatedSprite2D.animation_finished.is_connected(Callable(self, "_on_animation_finished")):
		$AnimatedSprite2D.animation_finished.connect(Callable(self, "_on_animation_finished"))
	if not $AnimatedSprite2D.frame_changed.is_connected(Callable(self, "_on_frame_changed")):
		$AnimatedSprite2D.frame_changed.connect(Callable(self, "_on_frame_changed"))
		
	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.init_health(max_health)


func _process(delta):
	handle_input(delta)
	handle_animation()

func handle_input(delta):
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

	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var push_force = velocity.normalized() * 1000
			collider.apply_central_force(push_force)

	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		var aim_direction = (get_global_mouse_position() - global_position).normalized()
		$AnimatedSprite2D.flip_h = aim_direction.x < 0
		$AnimatedSprite2D.play("attack")

func handle_animation():
	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.animation = "run" if velocity.length() > walk_speed else "walk"
	else:
		$AnimatedSprite2D.animation = "idle"

	$AnimatedSprite2D.flip_h = velocity.x < 0
	$AnimatedSprite2D.flip_v = false
	$AnimatedSprite2D.play()

func shoot_lightning_ball():
	var lightning = projectile_scene.instantiate()
	var aim_direction = (get_global_mouse_position() - global_position).normalized()

	var offset = projectile_offset
	if $AnimatedSprite2D.flip_h:
		offset.x *= -1

	lightning.global_position = global_position + offset
	lightning.velocity = aim_direction * lightning.speed
	lightning.rotation = aim_direction.angle()

	get_tree().get_current_scene().add_child(lightning)

func _on_frame_changed():
	if $AnimatedSprite2D.animation == "attack":
		var impact_frame = 3  # afvuren op frame 3
		if $AnimatedSprite2D.frame == impact_frame:
			shoot_lightning_ball()

func _on_animation_finished():
	match $AnimatedSprite2D.animation:
		"attack":
			is_attacking = false
		"death":
			queue_free()

func _on_Hitbox_body_entered(body: Node):
	if is_invincible:
		return
	if body.is_in_group("Mobs"):
		take_damage(10)

func take_damage(amount: int):
	if is_invincible:
		return

	health = clamp(health - amount, 0, max_health)
	emit_signal("hit", health)

	# ✅ Update HealthBar node if it exists
	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.health = health

	if health == 0:
		die()
		if get_parent().has_method("game_over"):
			get_parent().game_over()

	is_invincible = true
	$AnimatedSprite2D.modulate.a = 0.3
	await get_tree().create_timer(2.0).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0


	is_invincible = true
	$AnimatedSprite2D.modulate.a = 0.3
	await get_tree().create_timer(2.0).timeout
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0

func die():
	is_attacking = false
	is_invincible = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.sprite_frames.set_animation_loop("death", false)
	$AnimatedSprite2D.play("death")

func start(pos: Vector2):
	position = pos
	show()
	$CollisionShape2D.disabled = false

	# ✅ Initialize the health bar here instead of _ready
	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.init_health(max_health)
