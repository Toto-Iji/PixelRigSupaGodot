extends Control

@onready var email_field = $emailTextEdit
@onready var password_field = $passwordTextEdit
@onready var signup_button = $SignupButton
@onready var login_redirect = $LoginRedirectButton

func _ready():
	# Configure for mobile
	email_field.editable = true
	email_field.selecting_enabled = true
	email_field.virtual_keyboard_enabled = true
	
	password_field.editable = true
	password_field.selecting_enabled = true
	password_field.virtual_keyboard_enabled = true
	password_field.secret = true
	
	# Force focus on tap
	email_field.focus_entered.connect(_on_email_focus)
	password_field.focus_entered.connect(_on_password_focus)
	
	signup_button.pressed.connect(_on_signup_button_pressed)
	login_redirect.pressed.connect(_on_login_redirect_button_pressed)

func _on_email_focus():
	email_field.select_all()
	email_field.deselect()

func _on_password_focus():
	password_field.select_all()
	password_field.deselect()

func _on_signup_button_pressed():
	var email = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()
	
	if email.is_empty() or password.is_empty():
		DebugLog.logv(["Signup Status: Please fill in all fields."])
		return
	
	DebugLog.logv(["Signup Status: Attempting to create account for", email])
	signup_button.disabled = true
	
	Supabase.sign_up(email, password, Callable(self, "_on_signup_response"))

func _on_signup_response(data, code):
	signup_button.disabled = false
	
	if code == 200 and data.has("user"):
		DebugLog.logv(["Signup Status: Signup successful! Account created."])
		DebugLog.logv(["Signup Status: Please log in to continue."])
		get_tree().change_scene_to_file("res://scenes/login.tscn")
	else:
		DebugLog.logv(["Signup Status: Signup failed. Code:", code, "Data:", data])

func _on_login_redirect_button_pressed():
	get_tree().change_scene_to_file("res://scenes/login.tscn")
