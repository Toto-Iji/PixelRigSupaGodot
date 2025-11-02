# quiz_button.gd - FOR BUTTON NODE
extends Button

signal selected
signal deselected

@onready var quiz_name_label = $MarginContainer/VBoxContainer/QuizNameLabel
@onready var status_label = $MarginContainer/VBoxContainer/StatusLabel
@onready var score_label = $MarginContainer/VBoxContainer/ScoreLabel

var _is_selected: bool = false
var _quiz_data: Dictionary = {}

func _ready():
	# Set button properties
	custom_minimum_size = Vector2(180, 75)  # Set minimum button size
	text = ""  # Clear button text (we use labels instead)
	
	# Configure labels
	if quiz_name_label:
		quiz_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if status_label:
		status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	if score_label:
		score_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	pressed.connect(_on_button_pressed)

func setup(quiz_data: Dictionary):
	_quiz_data = quiz_data
	
	if quiz_name_label:
		quiz_name_label.text = quiz_data.get("level_name", "Unknown Quiz")
	
	if quiz_data.is_unlocked:
		var score = quiz_data.get("score", 0)
		var total = quiz_data.get("total", 5)
		var percentage = (float(score) / float(total)) * 100.0 if total > 0 else 0.0
		
		if status_label:
			status_label.text = "✅ Unlocked"
		if score_label:
			score_label.text = "Best: %d/%d (%.0f%%)" % [score, total, percentage]
	else:
		if status_label:
			status_label.text = "🔒 Locked"
		if score_label:
			score_label.text = "Complete in-game first"
		disabled = true  # Disable button if locked

func _on_button_pressed():
	if _quiz_data.is_unlocked:
		toggle_selection()

func toggle_selection():
	set_selected(not _is_selected)

func set_selected(value: bool):
	if _is_selected == value:
		return
	
	_is_selected = value
	
	if _is_selected:
		modulate = Color(1.3, 1.3, 1.0)  # Highlighted
		selected.emit()
	else:
		modulate = Color(1, 1, 1)  # Normal
		deselected.emit()
