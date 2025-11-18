extends Area2D

# NEW signals to report what happened
signal dropped_on_socket
signal dropped_off_socket # For snapping back

var is_dragging = false
var is_over_socket = false
var start_position = Vector2.ZERO

func _ready():
	start_position = global_position
	connect("input_event", _on_input_event)
	connect("area_entered", _on_area_entered)
	connect("area_exited", _on_area_exited)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_dragging = true
		else:
			# --- MOUSE RELEASED ---
			is_dragging = false
			if is_over_socket:
				# Tell the main game we were dropped on the socket
				emit_signal("dropped_on_socket")
			else:
				# Tell the main game we were dropped in the wrong place
				emit_signal("dropped_off_socket")

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position()

# --- Socket Detection (unchanged) ---
func _on_area_entered(area):
	if area.is_in_group("socket"):
		is_over_socket = true

func _on_area_exited(area):
	if area.is_in_group("socket"):
		is_over_socket = false

# --- NEW Functions (The main game will call these) ---

# This will be called by MiniGame.gd
func snap_to_socket(socket_pos):
	global_position = socket_pos
	# Disable this script. We're done!
	set_process(false)
	$CollisionShape2D.disabled = true # Stop detecting clicks

# This will be called by MiniGame.gd
func snap_back_to_start():
	global_position = start_position
