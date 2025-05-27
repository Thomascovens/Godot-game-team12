# health_bar_mob.gd
extends ProgressBar

@onready var timer: Timer             = $Timer
@onready var damage_bar: ProgressBar  = $DamageBar

var mob  # the Mob this bar is tracking

func _ready() -> void:
	mob = get_parent()

	# Connect mob's "hit" signal if not already connected
	if mob and not mob.is_connected("hit", Callable(self, "_on_mob_health_changed")):
		mob.connect("hit", Callable(self, "_on_mob_health_changed"))

	# Connect the timer's "timeout" signal safely
	if not timer.is_connected("timeout", Callable(self, "_on_timer_timeout")):
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))

	# Wait until the next idle frame to initialize health values safely
	call_deferred("_init_bar")


func _init_bar() -> void:
	# Now mob.health has been set in the mob’s _ready()
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
	# after the delay, slide the damage bar to catch up
	damage_bar.value = value
