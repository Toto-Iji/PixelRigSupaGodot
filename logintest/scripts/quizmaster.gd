extends Area2D

const QUIZ_UI_SCENE = preload("res://scenes/quiz_ui.tscn")

@export var level_id: String = "level_1"
@export var reward_type: String = "component"  # "component" or "tool"
@export var reward_id: String = "cpu"

var quiz_completed: bool = false
var quiz_ui_instance = null

func interact():
	if quiz_completed:
		print("You already completed this quiz!")
		return
	
	# Instantiate quiz UI dynamically
	quiz_ui_instance = QUIZ_UI_SCENE.instantiate()
	get_tree().root.add_child(quiz_ui_instance)
	
	# Define questions (can move to external JSON/resource later)
	var questions = _get_questions_for_level()
	
	# Connect completion signal and show quiz
	quiz_ui_instance.quiz_completed.connect(_on_quiz_completed)
	quiz_ui_instance.show_quiz(questions)

func _get_questions_for_level() -> Array:
	# You can load from JSON or use a match statement per level
	return [
		{
			"text": "What does CPU stand for?",
			"answers": ["Central Processing Unit", "Computer Personal Unit", "Central Program Utility", "Core Processing Usage"],
			"correct": 0
		},
		{
			"text": "What is the CPU's primary function?",
			"answers": ["Store data", "Process instructions", "Display graphics", "Connect to internet"],
			"correct": 1
		}
	]

func _on_quiz_completed(score: int, total: int):
	quiz_completed = true
	print("Quiz score:", score, "/", total)
	
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
