# mobile_controls.gd
extends CanvasLayer

@onready var joystick_base = $MovementJoystick/JoystickBase
@onready var joystick_knob = $MovementJoystick/JoystickKnob
@onready var attack_button = $ActionButtons/AttackButton
@onready var interact_button = $ActionButtons/InteractButton
@onready var pause_button = $PauseButton

var is_dragging: bool = false
var joystick_center: Vector2
var max_distance: float = 50.0
var current_direction: Vector2 = Vector2.ZERO

# Input state tracking
var virtual_left: bool = false
var virtual_right: bool = false
var virtual_up: bool = false
var virtual_down: bool = false

func _ready():
	# Set process mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not _is_mobile_platform():
		hide()
		return

	# Calculate joystick center
	joystick_center = joystick_base.position + joystick_base.size / 2

	# Setup joystick input
	joystick_base.gui_input.connect(_on_joystick_input)
	joystick_knob.gui_input.connect(_on_joystick_input)

	# 🆕 ENABLE MULTI-TOUCH: Set mouse filter to PASS for all buttons
	attack_button.mouse_filter = Control.MOUSE_FILTER_PASS
	interact_button.mouse_filter = Control.MOUSE_FILTER_PASS
	pause_button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect Action buttons
	attack_button.button_down.connect(_on_attack_pressed)
	attack_button.button_up.connect(_on_attack_released)
	interact_button.pressed.connect(_on_interact_pressed)
	
	# Connect Pause button
	if is_instance_valid(pause_button):
		pause_button.pressed.connect(_on_pause_button_pressed)
	
	print("📱 Mobile controls enabled")

func _is_mobile_platform() -> bool:
	# ✅ For HTML5 (Web) builds, use JavaScript user agent detection
	if OS.has_feature("web"):
		var js_code = "(/Android|iPhone|iPad|iPod|Windows Phone|BlackBerry|Mobile/i.test(navigator.userAgent))"
		return JavaScriptBridge.eval(js_code)
	
	# ✅ For native mobile builds
	return OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"]

func _on_joystick_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			_update_joystick(event.position)
		else:
			is_dragging = false
			_reset_joystick()
	
	elif event is InputEventScreenDrag and is_dragging:
		_update_joystick(event.position)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				_update_joystick(event.position)
			else:
				is_dragging = false
				_reset_joystick()
	
	elif event is InputEventMouseMotion and is_dragging:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2):
	var local_pos = joystick_base.get_local_mouse_position()
	var offset = local_pos - (joystick_base.size / 2)
	var distance = offset.length()

	if distance > max_distance:
		offset = offset.normalized() * max_distance

	joystick_knob.position = (joystick_base.size / 2) + offset - (joystick_knob.size / 2)
	current_direction = offset / max_distance

func _reset_joystick():
	joystick_knob.position = (joystick_base.size / 2) - (joystick_knob.size / 2)
	current_direction = Vector2.ZERO

func _process(_delta):
	var threshold = 0.3
	
	# Horizontal
	if current_direction.x > threshold:
		if not virtual_right:
			Input.action_press("Right")
			virtual_right = true
	else:
		if virtual_right:
			Input.action_release("Right")
			virtual_right = false
	
	if current_direction.x < -threshold:
		if not virtual_left:
			Input.action_press("Left")
			virtual_left = true
	else:
		if virtual_left:
			Input.action_release("Left")
			virtual_left = false
	
	# Vertical
	if current_direction.y > threshold:
		if not virtual_down:
			Input.action_press("Down")
			virtual_down = true
	else:
		if virtual_down:
			Input.action_release("Down")
			virtual_down = false
	
	if current_direction.y < -threshold:
		if not virtual_up:
			Input.action_press("Up")
			virtual_up = true
	else:
		if virtual_up:
			Input.action_release("Up")
			virtual_up = false

func _on_attack_pressed():
	Input.action_press("Attack")

func _on_attack_released():
	Input.action_release("Attack")

func _on_interact_pressed():
	Input.action_press("Interact")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("Interact")

func _on_pause_button_pressed():
	print("Pause button pressed")
	
	# Get the world/game scene (parent)
	var world = get_parent()
	
	if world and world.has_method("open_pause_menu"):
		world.open_pause_menu()
	else:
		# Fallback: simulate ESC key
		Input.action_press("ui_cancel")
		await get_tree().create_timer(0.1).timeout
		Input.action_release("ui_cancel")

func _exit_tree():
	if virtual_left:
		Input.action_release("Left")
	if virtual_right:
		Input.action_release("Right")
	if virtual_up:
		Input.action_release("Up")
	if virtual_down:
		Input.action_release("Down")
