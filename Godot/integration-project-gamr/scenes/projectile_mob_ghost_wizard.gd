extends Area2D
class_name EnemyProjectile

@export var speed: float = 400.0    # tweak to taste
@export var damage: int = 10

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# free when off‐screen
	$VisibilityNotifier2D.screen_exited.connect(Callable(self, "queue_free"))
	# detect hits
	body_entered.connect(Callable(self, "_on_body_entered"))

	# start the “fly” animation
	$AnimatedSprite2D.animation = "fly"
	$AnimatedSprite2D.play()

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	# only hit once
	body_entered.disconnect(Callable(self, "_on_body_entered"))

	# deal damage
	if body.has_method("take_damage"):
		body.take_damage(damage)

func _on_screen_exited() -> void:
	queue_free()
