extends ProgressBar

@onready var timer: Timer            = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

var mob: RigidBody2D

func _ready() -> void:
	mob = get_parent()
	mob.connect("hit", Callable(self, "_on_mob_health_changed"))
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	# wait until next idle frame, then do the real init:
	call_deferred("_init_bar")

func _init_bar() -> void:
	max_value            = mob.max_health
	value                = mob.health
	damage_bar.max_value = mob.max_health
	damage_bar.value     = mob.health

func _on_mob_health_changed(new_health: int) -> void:
	new_health = clamp(new_health, 0, max_value)
	value = new_health
	if new_health < damage_bar.value:
		timer.start()
	else:
		damage_bar.value = new_health

func _on_timer_timeout() -> void:
	damage_bar.value = value
