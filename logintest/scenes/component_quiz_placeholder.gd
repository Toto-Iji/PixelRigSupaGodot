extends Control

@onready var question_label = $VBoxContainer/QuestionLabel
@onready var answer_container = $VBoxContainer/AnswerContainer
@onready var feedback_label = $VBoxContainer/FeedbackLabel

func _ready():
	var component = GameData.get_current_component()
	
	if component.is_empty():
		push_error("No component data found!")
		_return_to_build()
		return
	
	question_label.text = component.quiz_question
	
	# Parse answers from JSONB
	var answers = component.quiz_answers
	for answer in answers:
		var button = Button.new()
		button.text = answer.text
		button.pressed.connect(_on_answer_selected.bind(answer.correct))
		answer_container.add_child(button)

func _on_answer_selected(is_correct: bool):
	if is_correct:
		feedback_label.text = "✅ Correct! Loading minigame..."
		feedback_label.modulate = Color.GREEN
		await get_tree().create_timer(1.0).timeout
		_go_to_minigame()
	else:
		feedback_label.text = "❌ Wrong! Try again."
		feedback_label.modulate = Color.RED

func _go_to_minigame():
	var component = GameData.get_current_component()
	var minigame_path = component.minigame_scene_path
	
	# Check if scene exists
	if ResourceLoader.exists(minigame_path):
		get_tree().change_scene_to_file(minigame_path)
	else:
		feedback_label.text = "⚠️ Minigame not implemented yet! (Path: %s)" % minigame_path
		await get_tree().create_timer(2.0).timeout
		_return_to_build()

func _return_to_build():
	GameData.clear_current_component()
	get_tree().change_scene_to_file("res://scenes/main_menu_screen.tscn")
