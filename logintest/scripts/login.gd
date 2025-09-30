extends Control

@onready var email_field = $emailTextEdit 
@onready var password_field = $passwordTextEdit
@onready var login_button = $LoginButton
@onready var signup_redirect = $SignupRedirectButton

func _ready():
	login_button.pressed.connect(_on_login_pressed)

func _on_login_pressed():
	var email = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()

	if email.is_empty() or password.is_empty():
		print("Login Status: Please fill in all fields.")
		return

	login_button.disabled = true
	Supabase.sign_in(email, password, Callable(self, "_on_login_response"))

# --- NEW CALLBACK FUNCTION for the username lookup ---
func _on_email_lookup_response(lookup_data, code, password):
	if code == 200 and not lookup_data.is_empty():
		# The lookup was successful and returned an array with the user's data.
		var found_email = lookup_data[0].get("email", "")
		if not found_email.is_empty():
			print("Login Status: Email found for username. Proceeding to login with: ", found_email)
			# Now that we have the email, we can call the normal sign_in function.
			Supabase.sign_in(found_email, password, Callable(self, "_on_login_response"))
		else:
			print("Login Status: Error - Username found, but no email was associated with it.")
			login_button.disabled = false
	else:
		print("Login Status: Login failed. Could not find a user with that username.")
		print("Supabase Error: Code ", code, ", Data: ", lookup_data)
		login_button.disabled = false
		
# This function remains the SAME. It's the final step for both login paths.
func _on_login_response(data, code):
	if code == 200 and data.has("user"):
		print("Login Status: Step 1/2 - Authentication successful.")
		print("Login Status: Step 2/2 - Fetching user profile...")
		Supabase.get_profile(Callable(self, "_on_profile_loaded"))
	else:
		print("Login Status: Login failed. Please check your credentials.")
		print("Supabase Error: Code ", code, ", Data: ", data)
		login_button.disabled = false

# This function also remains the SAME.
func _on_profile_loaded(data, code):
	login_button.disabled = false
	
	if code == 200 and not data.is_empty():
		print("Login Status: Step 2/2 - Profile loaded successfully.")
		print("Login Status: Redirecting to main menu...")
		get_tree().change_scene_to_file("res://scenes/main_menu_screen.tscn")
	else:
		print("Login Status: Critical error - Could not load user profile after login.")
		print("Supabase Error: Code ", code, ", Data: ", data)

func _on_signup_redirect_button_pressed():
	get_tree().change_scene_to_file("res://scenes/signup.tscn")
