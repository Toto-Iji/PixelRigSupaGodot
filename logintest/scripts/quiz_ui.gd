extends CanvasLayer

signal quiz_completed(score: int, total: int)

@onready var panel = $Panel
@onready var question_label = $Panel/Label
@onready var answers_container = $Panel/VBoxContainer
@onready var feedback_label = $Panel/FeedbackLabel

var questions: Array = []
var current_index: int = 0
var correct_count: int = 0

func _ready():
	# 🔹 CRITICAL: Set process mode so UI works during pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_quiz()

func show_quiz(q_list: Array):
	questions = q_list
	current_index = 0
	correct_count = 0
	panel.visible = true
	get_tree().paused = true
	show_question()

func hide_quiz():
	panel.visible = false
	get_tree().paused = false

func show_question():
	var q = questions[current_index]
	question_label.text = q["text"]
	feedback_label.text = ""

	# Clear old buttons
	for child in answers_container.get_children():
		child.queue_free()

	# Create answer buttons
	for i in range(q["answers"].size()):
		var btn = Button.new()
		btn.text = q["answers"][i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# 🔹 IMPORTANT: Make buttons work during pause
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		
		btn.pressed.connect(func() -> void: on_answer_pressed(i, q["correct"]))
		answers_container.add_child(btn)

func on_answer_pressed(index: int, correct_index: int):
	if index == correct_index:
		correct_count += 1
		feedback_label.text = "✅ Correct!"
		await get_tree().create_timer(0.75).timeout
		current_index += 1
		
		if current_index < questions.size():
			show_question()
		else:
			finish_quiz()
	else:
		feedback_label.text = "❌ Wrong! Try again."

func finish_quiz():
	hide_quiz()
	quiz_completed.emit(correct_count, questions.size())
