extends Node2D

@onready var darkness = $Darkness  # ColorRect with shader
@onready var room_dim = $RoomDim
@onready var entrance_area = $EntranceArea2D
@onready var room_center = $RoomCenter  # Optional for camera pan

var room_revealed = false
var camera: Camera2D
var darkness_start_position: Vector2  # ← NEW: Store original position

func _ready():
	entrance_area.body_entered.connect(_on_player_entered)
	entrance_area.body_exited.connect(_on_player_exited)
	
	# Reset darkness state for fresh level start
	darkness_start_position = darkness.position  # ← Store original position
	darkness.visible = true                      # ← Always show at start
	darkness.position = darkness_start_position  # ← Reset position
	room_dim.modulate.a = 0.0
	
	# Reset reveal state
	room_revealed = false  # ← Reset flag

func _on_player_entered(body):
	if body.is_in_group("player"):
		if not room_revealed:
			camera = body.get_node("PlayerCamera")
			_reveal_room_with_shader()
		else:
			_brighten_room()

func _on_player_exited(body):
	if body.is_in_group("player") and room_revealed:
		_darken_room()

func _reveal_room_with_shader():
	room_revealed = true
	
	# Optional: Camera pan to room center
	if camera and room_center:
		var original_pos = camera.global_position
		var center = room_center.global_position
		var cam_tween = create_tween()
		cam_tween.tween_property(camera, "global_position", center, 0.6).set_ease(Tween.EASE_IN_OUT)
		cam_tween.tween_interval(0.8)
		cam_tween.tween_property(camera, "global_position", original_pos, 0.5).set_ease(Tween.EASE_IN_OUT)
	
	# Wipe darkness by moving it
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(darkness, "position:x", darkness.position.x + 2000, 2.0)
	tween.tween_callback(_on_reveal_complete)

func _on_reveal_complete():
	# Hide darkness after shader reveal finishes
	darkness.visible = false

func _brighten_room():
	var tween = create_tween()
	tween.tween_property(room_dim, "modulate:a", 0.0, 0.0)

func _darken_room():
	var tween = create_tween()
	tween.tween_property(room_dim, "modulate:a", 0.5, 0.0)
