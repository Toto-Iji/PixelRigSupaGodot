extends Area2D

signal dropped_on_socket
signal dropped_off_socket

var is_dragging = false
var is_over_socket = false
var start_position = Vector2.ZERO

func _ready():
	start_position = position  # ← Use local position, not global
	input_pickable = true
	input_event.connect(_on_input_event)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_dragging = true
		else:
			is_dragging = false
			if is_over_socket:
				dropped_on_socket.emit()
			else:
				dropped_off_socket.emit()

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position()

func _on_area_entered(area):
	if area.is_in_group("socket"):
		is_over_socket = true

func _on_area_exited(area):
	if area.is_in_group("socket"):
		is_over_socket = false

func snap_to_socket(socket_pos):
	var tween = create_tween()
	tween.tween_property(self, "global_position", socket_pos, 0.3).set_ease(Tween.EASE_OUT)
	await tween.finished
	set_process(false)
	$CollisionShape2D.disabled = true

func snap_back_to_start():
	print("🔙 Snapping back to:", start_position)
	visible = true
	set_process(true)
	$CollisionShape2D.disabled = false
	
	var tween = create_tween()
	tween.tween_property(self, "position", start_position, 0.3).set_ease(Tween.EASE_OUT)  # ← Use position, not global_position
