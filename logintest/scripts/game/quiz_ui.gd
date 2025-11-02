# quiz_ui.gd - WITH DEBUG PRINTS
extends CanvasLayer

signal quiz_completed(score: int, total: int)

@onready var panel = $Panel
@onready var question_label = $Panel/Label
@onready var answers_container = $Panel/VBoxContainer
@onready var feedback_label = $Panel/FeedbackLabel

var questions: Array = []
var current_index: int = 0
var correct_count: int = 0
var current_level_id: String = ""
var is_from_exercise_panel: bool = false
var has_answered_correctly: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_quiz()

func show_quiz(q_list: Array, level_id: String = "", from_exercise: bool = false):
	questions = q_list
	current_level_id = level_id
	is_from_exercise_panel = from_exercise
	current_index = 0
	correct_count = 0
	panel.visible = true
	get_tree().paused = true
	print("🎮 Starting quiz with %d questions" % questions.size())
	show_question()

func hide_quiz():
	panel.visible = false
	get_tree().paused = false

func show_question():
	if current_index >= questions.size():
		finish_quiz()
		return
	
	var q = questions[current_index]
	question_label.text = q.get("question_text", q.get("text", ""))
	feedback_label.text = ""
	has_answered_correctly = false
	
	print("📝 Question %d/%d - Current score: %d" % [current_index + 1, questions.size(), correct_count])

	# Clear old buttons
	for child in answers_container.get_children():
		child.queue_free()

	# Handle database format
	if q.has("option_a"):
		var answers = [q.option_a, q.option_b, q.option_c, q.option_d]
		var correct_letter = q.get("correct_answer", "a").to_lower()
		var correct_index = {"a": 0, "b": 1, "c": 2, "d": 3}.get(correct_letter, 0)
		
		for i in range(answers.size()):
			_create_answer_button(answers[i], i, correct_index)
	else:
		var answers = q.get("answers", [])
		var correct_index = q.get("correct", 0)
		
		for i in range(answers.size()):
			_create_answer_button(answers[i], i, correct_index)

func _create_answer_button(answer_text: String, index: int, correct_index: int):
	var btn = Button.new()
	btn.text = answer_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(func() -> void: on_answer_pressed(index, correct_index))
	answers_container.add_child(btn)

func on_answer_pressed(index: int, correct_index: int):
	print("🖱️ Answer pressed: %d (correct: %d), has_answered_correctly: %s" % [index, correct_index, str(has_answered_correctly)])
	
	if index == correct_index:
		if not has_answered_correctly:
			correct_count += 1
			has_answered_correctly = true
			print("✅ CORRECT on first try! Score: %d/%d" % [correct_count, questions.size()])
		else:
			print("✅ Correct, but already answered this question (no points)")
		
		feedback_label.text = "✅ Correct!"
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
		
		await get_tree().create_timer(0.75).timeout
		current_index += 1
		show_question()
	else:
		has_answered_correctly = true  # 🆕 Mark as answered (wrong)
		print("❌ WRONG answer! This question won't count anymore.")
		
		feedback_label.text = "❌ Wrong! Try again."
		feedback_label.add_theme_color_override("font_color", Color.RED)

func finish_quiz():
	print("🏁 Quiz finished! Final score: %d/%d" % [correct_count, questions.size()])
	hide_quiz()
	
	if not current_level_id.is_empty():
		if not is_from_exercise_panel:
			QuizManager.unlock_quiz(current_level_id)
		
		QuizManager.update_quiz_score(current_level_id, correct_count, questions.size())
		
		Supabase.save_quiz_score(current_level_id, correct_count, questions.size(), 
			Callable(self, "_on_score_saved"))
	
	quiz_completed.emit(correct_count, questions.size())

func _on_score_saved(data, code):
	if code != 200 and code != 201:
		push_error("❌ Failed to save quiz score. Code: %d" % code)
	else:
		print("✅ Quiz score saved: %d/%d" % [correct_count, questions.size()])
