extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	rotation = direction.angle()
	animated_sprite.play("anims")  # Play the animation

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
			queue_free()
