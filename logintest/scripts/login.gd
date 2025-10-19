extends Control

@onready var email_field = $emailTextEdit
@onready var password_field = $passwordTextEdit
@onready var action_button = $LoginButton
@onready var signup_redirect = $SignupRedirectButton

var is_signup_mode = false

func _ready():
	action_button.pressed.connect(_on_action_pressed)
	signup_redirect.pressed.connect(_on_signup_redirect_button_pressed)
	email_field.connect("text_submitted", Callable(self, "_on_action_pressed"))
	password_field.connect("text_submitted", Callable(self, "_on_action_pressed"))

func _on_action_pressed(_text = ""):
	if is_signup_mode:
		_on_signup_pressed()
	else:
		_on_login_pressed()

func _on_login_pressed():
	var email = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()

	if email.is_empty() or password.is_empty():
		DebugLog.logv(["Login Status: Please fill in all fields."])
		return

	DebugLog.logv(["Login Status: Attempting login for", email])
	action_button.disabled = true
	Supabase.sign_in(email, password, Callable(self, "_on_login_response"))

func _on_signup_pressed():
	var email = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()

	if email.is_empty() or password.is_empty():
		DebugLog.logv(["Signup Status: Please fill in all fields."])
		return

	DebugLog.logv(["Signup Status: Creating account for", email])
	action_button.disabled = true
	Supabase.sign_up(email, password, Callable(self, "_on_signup_response"))

func _on_login_response(data, code):
	action_button.disabled = false
	if code == 200 and data.has("user"):
		DebugLog.logv(["Login Status: Successful. Redirecting..."])
		get_tree().change_scene_to_file("res://scenes/main_menu_screen.tscn")
	else:
		DebugLog.logv(["Login failed:", code, data])

func _on_signup_response(data, code):
	action_button.disabled = false
	if code == 200:
		DebugLog.logv(["Signup successful! You can now log in."])
		_on_signup_redirect_button_pressed() # Go back to login mode
	else:
		DebugLog.logv(["Signup failed:", code, data])

func _on_signup_redirect_button_pressed():
	is_signup_mode = !is_signup_mode

	if is_signup_mode:
		action_button.text = "Sign Up"
		signup_redirect.text = "Back to Login"
	else:
		action_button.text = "Login"
		signup_redirect.text = "Go to Sign Up"
