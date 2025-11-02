extends Control

@onready var ui_container = $CenterContainer/VBoxContainer  # Add this
@onready var email_field = $CenterContainer/VBoxContainer/emailTextEdit
@onready var password_field = $CenterContainer/VBoxContainer/passwordTextEdit
@onready var signup_button = $CenterContainer/VBoxContainer/MarginContainer/SignupButton
@onready var login_redirect = $LoginRedirectButton
@onready var signup_status = $CenterContainer/VBoxContainer/SignupStatus

# --- Mobile UX Variables ---
var initial_ui_position: Vector2
var keyboard_active: bool = false

func _ready():
	initial_ui_position = ui_container.position
	
	# Mobile keyboard handling
	email_field.focus_entered.connect(_on_any_field_focused.bind(email_field))
	password_field.focus_entered.connect(_on_any_field_focused.bind(password_field))
	email_field.focus_exited.connect(_on_any_field_unfocused)
	password_field.focus_exited.connect(_on_any_field_unfocused)
	
	password_field.secret = true
	signup_button.pressed.connect(_on_signup_button_pressed)
	login_redirect.pressed.connect(_on_login_redirect_button_pressed)

func _on_any_field_focused(focused_node: LineEdit):
	if OS.has_feature("mobile"):
		keyboard_active = true
		var tween = create_tween()
		var target_y = get_viewport_rect().size.y / 3 - focused_node.global_position.y + initial_ui_position.y
		tween.tween_property(ui_container, "position:y", target_y, 0.25).set_trans(Tween.TRANS_SINE)

func _on_any_field_unfocused():
	if OS.has_feature("mobile") and keyboard_active:
		keyboard_active = false
		var tween = create_tween()
		tween.tween_property(ui_container, "position", initial_ui_position, 0.25).set_trans(Tween.TRANS_SINE)

func _on_signup_button_pressed():
	var email = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()
	
	if email.is_empty() or password.is_empty():
		signup_status.text = "❌ Please fill in all fields."
		return
	
	if password.length() < 6:
		signup_status.text = "❌ Password must be at least 6 characters."
		return
	
	signup_status.text = "Creating account..."
	signup_button.disabled = true
	Supabase.sign_up(email, password, Callable(self, "_on_signup_response"))

func _on_signup_response(data, code):
	signup_button.disabled = false
	
	if code == 200 and data.has("user"):
		signup_status.text = "✅ Account created! Redirecting to login..."
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/login.tscn")
	else:
		signup_status.text = "❌ Signup failed. Please try again."
		push_error("Signup failed - Code: %d" % code)

func _on_login_redirect_button_pressed():
	get_tree().change_scene_to_file("res://scenes/login.tscn")
