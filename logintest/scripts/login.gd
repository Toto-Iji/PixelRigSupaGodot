extends Control

@onready var ui_container = $CenterContainer/VBoxContainer
@onready var email_field = $CenterContainer/VBoxContainer/emailTextEdit
@onready var password_field = $CenterContainer/VBoxContainer/passwordTextEdit
@onready var login_button = $CenterContainer/VBoxContainer/MarginContainer/LoginButton
@onready var signup_redirect = $SignupRedirectButton
@onready var login_status = $CenterContainer/VBoxContainer/LoginStatus

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

	password_field.secret = true
	_clear_status()

# --- Status Message Helpers ---

func _set_status(message: String, is_error: bool = false):
	"""Sets the status label text with appropriate styling."""
	if login_status:
		login_status.text = message
		login_status.modulate = Color.RED if is_error else Color.WHITE

func _clear_status():
	"""Clears the status label."""
	if login_status:
		login_status.text = ""

# --- Mobile Keyboard Handling ---

func _on_any_field_focused(focused_node: LineEdit):
	"""Handles keyboard activation and UI adjustment on mobile."""
	if not OS.has_feature("mobile"):
		return
		
	keyboard_active = true
	var tween = create_tween()
	var target_y = get_viewport_rect().size.y / 3 - focused_node.global_position.y + initial_ui_position.y
	tween.tween_property(ui_container, "position:y", target_y, 0.25).set_trans(Tween.TRANS_SINE)

func _on_any_field_unfocused():
	"""Resets UI position when keyboard is dismissed on mobile."""
	if not OS.has_feature("mobile") or not keyboard_active:
		return
		
	keyboard_active = false
	var tween = create_tween()
	tween.tween_property(ui_container, "position", initial_ui_position, 0.25).set_trans(Tween.TRANS_SINE)

# --- Login Logic ---

func _on_login_pressed():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.requestGameFullscreen();")
		
	_do_login()

func _do_login():
	var email = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()
	
	# Validate input fields
	if email.is_empty() and password.is_empty():
		_set_status("Please enter your email and password.", true)
		return
	
	if email.is_empty():
		_set_status("Please enter your email address.", true)
		return
		
	if password.is_empty():
		_set_status("Please enter your password.", true)
		return
	
	# Basic email format validation
	if not _is_valid_email(email):
		_set_status("Please enter a valid email address.", true)
		return
	
	# Attempt login
	_set_status("Logging in...")
	login_button.disabled = true
	Supabase.sign_in(email, password, Callable(self, "_on_login_response"))

func _is_valid_email(email: String) -> bool:
	"""Basic email format validation."""
	return email.contains("@") and email.contains(".")

func _on_login_response(data, code):
	"""Handles the response from Supabase authentication."""
	# Check for successful authentication
	if code == 200 and data.has("user"):
		_set_status("Login successful! Loading profile...")
		
		# Verify user data exists
		var current_user = Supabase.get_current_user()
		if current_user == null or not current_user.has("id"):
			_handle_login_error("Unable to retrieve user information.", code, data)
			return
			
		Supabase.get_profile(current_user["id"], Callable(self, "_on_profile_loaded"))
	else:
		# Handle authentication errors
		var error_message = _parse_auth_error(data, code)
		_handle_login_error(error_message, code, data)

func _parse_auth_error(data, code: int) -> String:
	"""Parses Supabase authentication errors into user-friendly messages."""
	match code:
		400:
			return "Invalid email or password. Please try again."
		401:
			return "Invalid email or password. Please try again."
		422:
			return "Invalid email format. Please check and try again."
		429:
			return "Too many login attempts. Please try again later."
		_:
			# Check for specific error messages in response
			if typeof(data) == TYPE_DICTIONARY:
				if data.has("error_description"):
					var error_desc = data["error_description"]
					if "Invalid" in error_desc or "invalid" in error_desc:
						return "Invalid email or password. Please try again."
				if data.has("message"):
					return data["message"]
			
			return "Login failed. Please check your connection and try again."

func _handle_login_error(message: String, code: int, data):
	"""Handles login errors by displaying message and re-enabling button."""
	login_button.disabled = false
	_set_status(message, true)
	push_error("Login failed - Code: %d, Data: %s" % [code, str(data)])

func _on_profile_loaded(data, code):
	"""Handles the response from profile fetch after successful login."""
	if code == 200:
		# Verify we still have a valid user session
		var current_user = Supabase.get_current_user()
		if current_user == null or not current_user.has("id"):
			_handle_profile_error("Session expired. Please try logging in again.", code, data)
			return
		
		_set_status("Welcome! Redirecting...")
		
		# Small delay before scene change for user feedback
		await get_tree().create_timer(0.5).timeout
		
		# Change scene
		var scene_change_error = get_tree().change_scene_to_file("res://scenes/main_menu/main_menu_screen.tscn")
		if scene_change_error != OK:
			_handle_profile_error("Failed to load main menu. Please restart the application.", code, data)
	else:
		var error_message = "Unable to load your profile. Please try again."
		_handle_profile_error(error_message, code, data)

func _handle_profile_error(message: String, code: int, data):
	"""Handles profile loading errors."""
	login_button.disabled = false
	_set_status(message, true)
	push_error("Profile fetch failed - Code: %d, Data: %s" % [code, str(data)])

func _on_signup_redirect_button_pressed():
	_set_status("Redirecting to signup...")
	var scene_change_error = get_tree().change_scene_to_file("res://scenes/signup.tscn")
	if scene_change_error != OK:
		_set_status("Failed to load signup page. Please try again.", true)
		push_error("Scene change failed: res://scenes/signup.tscn")
