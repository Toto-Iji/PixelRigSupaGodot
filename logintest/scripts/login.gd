extends Control

@onready var email_field = $emailTextEdit
@onready var password_field = $passwordTextEdit
@onready var login_button = $LoginButton
@onready var signup_redirect = $SignupRedirectButton

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	signup_redirect.pressed.connect(_on_signup_redirect_button_pressed)
func _on_login_pressed():
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
