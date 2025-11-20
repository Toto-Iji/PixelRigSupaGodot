extends Node2D

@onready var room_dim = $RoomDim
@onready var entrance_area = $EntranceArea2D

func _ready():
	entrance_area.body_entered.connect(_on_player_entered)
	entrance_area.body_exited.connect(_on_player_exited)
	room_dim.modulate.a = 0.0  # Start fully bright

func _on_player_entered(body):
	if body.is_in_group("player"):
		_brighten_room()

func _on_player_exited(body):
	if body.is_in_group("player"):
		_darken_room()

func _brighten_room():
	var tween = create_tween()
	tween.tween_property(room_dim, "modulate:a", 0.0, 0.0)

func _darken_room():
	var tween = create_tween()
	tween.tween_property(room_dim, "modulate:a", 0.5, 0.0)
