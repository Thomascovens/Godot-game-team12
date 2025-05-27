extends Area2D

@export var speed: float = 500.0
var velocity: Vector2 = Vector2.ZERO
var hit := false

@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	sprite.play("arrow_fly")

func _process(delta):
	if hit:
		return
	position += velocity * delta

func _on_body_entered(body):
	if hit:
		return
	hit = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)

	if body.is_in_group("Mobs") and body.has_method("take_damage"):
		body.take_damage(15)

	queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
