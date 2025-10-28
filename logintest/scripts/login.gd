extends Control

@onready var ui_container = $CenterContainer/VBoxContainer
@onready var email_field = $CenterContainer/VBoxContainer/emailTextEdit
@onready var password_field = $CenterContainer/VBoxContainer/passwordTextEdit
@onready var login_button = $CenterContainer/VBoxContainer/MarginContainer/LoginButton
@onready var signup_redirect = $SignupRedirectButton

# --- Mobile UX Variables ---
var initial_ui_position: Vector2
var keyboard_active: bool = false

func _ready():
	# Store the original, centered position of our UI elements.
	initial_ui_position = ui_container.position

	# Connect signals for focus events to handle the keyboard.
	email_field.focus_entered.connect(_on_any_field_focused.bind(email_field))
	password_field.focus_entered.connect(_on_any_field_focused.bind(password_field))

	# Connect focus_exited to reset the UI position.
	email_field.focus_exited.connect(_on_any_field_unfocused)
	password_field.focus_exited.connect(_on_any_field_unfocused)
	
	# Connect button presses.
	login_button.pressed.connect(_on_login_pressed)
	signup_redirect.pressed.connect(_on_signup_redirect_button_pressed)

	# You no longer need the mobile-specific prompt logic.
	# The virtual keyboard will now work correctly with the LineEdit nodes.
	password_field.secret = true

# --- Mobile Keyboard Handling ---

func _on_any_field_focused(focused_node: LineEdit):
	# This function is called whenever the user taps on an input field.
	# We only need to run this on mobile devices.
	if OS.has_feature("mobile"):
		keyboard_active = true
		# Create a smooth animation (a Tween) to move the UI up.
		var tween = create_tween()
		# We move it up so the focused field is in the top 1/3 of the screen.
		var target_y = get_viewport_rect().size.y / 3 - focused_node.global_position.y + initial_ui_position.y
		tween.tween_property(ui_container, "position:y", target_y, 0.25).set_trans(Tween.TRANS_SINE)

func _on_any_field_unfocused():
	# This function is called when the user taps away from an input field.
	if OS.has_feature("mobile") and keyboard_active:
		keyboard_active = false
		# Create a tween to animate the UI back to its original centered position.
		var tween = create_tween()
		tween.tween_property(ui_container, "position", initial_ui_position, 0.25).set_trans(Tween.TRANS_SINE)

# --- Login Logic (No changes needed here, remove the JS prompt parts) ---

func _on_login_pressed():
	# --- REMOVED: No longer need the JS prompt check ---
	_do_login()

func _do_login():
	var email = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()
	
	if email.is_empty() or password.is_empty():
		DebugLog.logv(["Login Status: Please fill in all fields."])
		return
	
	DebugLog.logv(["Login Status: Attempting login for", email])
	login_button.disabled = true
	Supabase.sign_in(email, password, Callable(self, "_on_login_response"))

func _on_login_response(data, code):
	if code == 200 and data.has("user"):
		DebugLog.logv(["Login Status: Step 1/2 - Authentication successful."])
		DebugLog.logv(["Login Status: Step 2/2 - Fetching user profile..."])
		Supabase.get_profile(Supabase.get_current_user()["id"], Callable(self, "_on_profile_loaded"))
	else:
		login_button.disabled = false
		DebugLog.logv(["Login Status: Login failed. Please check your credentials."])
		DebugLog.logv(["Supabase Error: Code", code, ", Data:", data])

func _on_profile_loaded(data, code):
	login_button.disabled = false
	
	DebugLog.logv(["=== PROFILE FETCH DEBUG ==="])
	DebugLog.logv(["Response code:", code])
	DebugLog.logv(["Data:", data])
	DebugLog.logv(["Current user BEFORE scene change:", Supabase.get_current_user()])
	DebugLog.logv(["User ID present?", Supabase.get_current_user().has("id")])
	if Supabase.get_current_user().has("id"):
		DebugLog.logv(["User ID value:", Supabase.get_current_user().get("id")])
	DebugLog.logv(["=== END DEBUG ==="])
	
	if code == 200: 
		DebugLog.logv(["Login Status: Step 2/2 - Profile fetch complete. Data:", data])
		DebugLog.logv(["Login Status: Redirecting to main menu..."])
		get_tree().change_scene_to_file("res://scenes/main_menu_screen.tscn")
	else:
		DebugLog.logv(["Login Status: Critical error - Could not load user profile after login."])
		DebugLog.logv(["Supabase Error: Code", code, ", Data:", data])

func _on_signup_redirect_button_pressed():
	get_tree().change_scene_to_file("res://scenes/signup.tscn")
