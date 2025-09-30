extends Control

@onready var email_field = $emailTextEdit
@onready var password_field = $passwordTextEdit
@onready var signup_button = $SignupButton
@onready var login_redirect = $LoginRedirectButton

func _ready():
	password_field.secret = true

func _on_signup_button_pressed():
	var email = email_field.text.strip_edges()
	# var username = username_field.text.strip_edges() <-- DELETE THIS LINE
	var password = password_field.text.strip_edges()

	if email.is_empty() or password.is_empty(): # <-- REMOVED USERNAME CHECK
		print("Signup Status: Please fill in all fields.")
		return
	
	print("Signup Status: Attempting to create account for ", email)
	signup_button.disabled = true
	# We now call sign_up without a username.
	Supabase.sign_up(email, password, "", Callable(self, "_on_signup_response"))

func _on_signup_response(data, code):
	signup_button.disabled = false
	
	if code == 200 and data.has("user"):
		print("Signup Status: Signup successful! Account created.")
		# A successful signup should take the user to the login screen
		# to reinforce the login habit and ensure the profile is fetched correctly.
		print("Signup Status: Please log in to continue.")
		get_tree().change_scene_to_file("res://scenes/login.tscn")
	else:
		print("Signup Status: Signup failed.")
		print("Supabase Error: Code ", code, ", Data: ", data)

func _on_login_redirect_button_pressed():
	get_tree().change_scene_to_file("res://scenes/login.tscn")
