extends CharacterBody2D
signal hit(new_health: int)

@export var walk_speed := 200
@export var run_speed := 350
@export var max_health: int = 150
@export var attack_damage: int = 30
@export var attack_frame: int = 3  # het frame waarop hitbox actief wordt

var health: int
var is_attacking := false
var is_invincible := false

@onready var sprite := $AnimatedSprite2D
@onready var hitbox := $Hitbox  # Area2D
@onready var collision := $CollisionShape2D
@onready var hitbox_shape := $Hitbox/CollisionShape2D

func _ready():
	health = max_health
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox_shape.disabled = true
	
	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.init_health(max_health)


func _process(delta):
	if is_attacking:
		return

	handle_input(delta)
	handle_animation()

func handle_input(delta):
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

	# Move with collision and apply push force to RigidBody2D
	var collision_result := move_and_collide(velocity * delta)
	if collision_result:
		var collider := collision_result.get_collider()
		if collider is RigidBody2D:
			var push_force = velocity.normalized() * 1000
			collider.apply_central_force(push_force)

	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		var dir_to_mouse = get_global_mouse_position() - global_position
		sprite.flip_h = dir_to_mouse.x < 0
		$Hitbox.rotation = dir_to_mouse.angle()
		sprite.play("attack")

func handle_animation():
	if is_attacking:
		return  # don't interrupt attack animation

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
		apply_melee_damage()

func _on_animation_finished():
	if sprite.animation == "attack":
		hitbox_shape.disabled = true
		hitbox.monitoring = false
		is_attacking = false
		sprite.play("idle")

func _on_hitbox_body_entered(body):
	if not is_attacking or hitbox_shape.disabled:
		return
	if body.is_in_group("Mobs") and body.has_method("take_damage"):
		body.take_damage(attack_damage)

func apply_melee_damage():
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("Mobs") and body.has_method("take_damage"):
			body.take_damage(attack_damage)

func take_damage(amount: int):
	if is_invincible:
		return

	health = clamp(health - amount, 0, max_health)
	emit_signal("hit", health)

	# ✅ Update HealthBar node if present
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
	$CollisionShape2D.disabled = false
	
	# ✅ Initialize the health bar here instead of _ready
	var health_bar = get_node_or_null("/root/Main/HUD/HealthBar")
	if health_bar:
		health_bar.init_health(max_health)
