# mobile_controls.gd
extends CanvasLayer

@onready var joystick_base = $MovementJoystick/JoystickBase
@onready var joystick_knob = $MovementJoystick/JoystickKnob
@onready var attack_button = $ActionButtons/AttackButton
@onready var interact_button = $ActionButtons/InteractButton
@onready var pause_button = $PauseButton

var joystick_center: Vector2
var joystick_finger := -1
var max_distance := 60.0
var current_direction := Vector2.ZERO

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	visible = false
	set_process(false)
	set_process_input(false)
	
	print("📱 Mobile Controls: Checking device...")
	
	if DeviceDetector.should_show_mobile_controls():
		print("✅ Mobile device with touchscreen detected!")
		visible = true
		set_process(true)
		set_process_input(true)
		
		await get_tree().process_frame
		joystick_center = joystick_base.global_position + joystick_base.size / 2
		print("📱 Mobile controls enabled at: ", joystick_center)
	else:
		print("🖥️ PC or no touchscreen - controls remain hidden")
		queue_free()

func _input(event):
	# Only process touch events
	if not event is InputEventScreenTouch and not event is InputEventScreenDrag:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_inside(event.position, joystick_base) and joystick_finger == -1:
				joystick_finger = event.index
				_update_joystick(event.position)
			elif _is_inside(event.position, attack_button):
				Input.action_press("Attack")
			elif _is_inside(event.position, interact_button):
				Input.action_press("Interact")
			elif _is_inside(event.position, pause_button):
				_on_pause_pressed()
		else:
			if event.index == joystick_finger:
				joystick_finger = -1
				_reset_joystick()
			Input.action_release("Attack")
			Input.action_release("Interact")
	
	elif event is InputEventScreenDrag and event.index == joystick_finger:
		_update_joystick(event.position)

func _update_joystick(pos: Vector2):
	var offset = pos - joystick_center
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance
	joystick_knob.global_position = joystick_center + offset - joystick_knob.size / 2
	current_direction = offset / max_distance

func _reset_joystick():
	joystick_knob.position = joystick_base.size / 2 - joystick_knob.size / 2
	current_direction = Vector2.ZERO

func _process(_delta):
	var threshold = 0.25
	var dir = current_direction
	
	_set_action("Right", dir.x > threshold)
	_set_action("Left", dir.x < -threshold)
	_set_action("Down", dir.y > threshold)
	_set_action("Up", dir.y < -threshold)

func _set_action(action: String, pressed: bool):
	if pressed and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not pressed and Input.is_action_pressed(action):
		Input.action_release(action)

func _is_inside(pos: Vector2, control: Control) -> bool:
	var rect = Rect2(control.global_position, control.size)
	return rect.has_point(pos)

func _on_pause_pressed():
	var world = get_parent()
	if world and world.has_method("open_pause_menu"):
		world.open_pause_menu()

func _exit_tree():
	Input.action_release("Left")
	Input.action_release("Right")
	Input.action_release("Up")
	Input.action_release("Down")
	Input.action_release("Attack")
	Input.action_release("Interact")
