# quizmaster.gd
extends Area2D

const QUIZ_UI_SCENE = preload("res://scenes/game/quiz_ui.tscn")

@export var level_id: String = "part_1"  # 🆕 CHANGED from "level_1" to "part_1"
@export var reward_type: String = "component"
@export var reward_id: String = "cpu"

var quiz_completed: bool = false
var quiz_ui_instance = null

func interact():
	if quiz_completed:
		print("✅ You already completed this quiz!")
		return
	
	# Check if questions are cached
	if QuizCache.has_questions(level_id):
		var questions = QuizCache.get_questions(level_id)
		_show_quiz(questions)
	else:
		# Fallback: load questions if not cached
		print("⚠️ Questions not cached, loading now...")
		Supabase.get_questions_for_level(level_id, Callable(self, "_on_questions_loaded"))

func _on_questions_loaded(data, code):
	if code != 200:
		push_error("❌ Failed to load quiz questions. Code: %d" % code)
		return
	
	if data.is_empty():
		push_error("❌ No questions found for level: %s" % level_id)
		return
	
	_show_quiz(data)

func _show_quiz(questions: Array):
	print("✅ Showing quiz with %d questions" % questions.size())
	
	# Instantiate quiz UI
	quiz_ui_instance = QUIZ_UI_SCENE.instantiate()
	get_tree().root.add_child(quiz_ui_instance)
	
	# Connect completion signal and show quiz
	quiz_ui_instance.quiz_completed.connect(_on_quiz_completed)
	quiz_ui_instance.show_quiz(questions, level_id, false)

func _on_quiz_completed(score: int, total: int):
	quiz_completed = true
	print("🎉 Quiz score:", score, "/", total)
	
	# Give reward
	if reward_type == "component":
		_give_component()
	elif reward_type == "tool":
		_give_tool()
	
	# Clean up quiz UI
	if quiz_ui_instance:
		quiz_ui_instance.queue_free()
		quiz_ui_instance = null

func _give_component():
	SolutionItem.receive_item({
		"type": SolutionItem.ItemType.COMPONENT,
		"id": reward_id,
		"name": SolutionItem.get_component_name(reward_id),
		"description": "A critical PC component.",
		"icon": "res://icons/" + reward_id + ".png"
	})

func _give_tool():
	SolutionItem.receive_item({
		"type": SolutionItem.ItemType.TOOL,
		"id": reward_id,
		"name": SolutionItem.get_tool_name(reward_id),
		"description": "Use this tool to clear obstacles.",
		"icon": "res://icons/" + reward_id + ".png"
	})
