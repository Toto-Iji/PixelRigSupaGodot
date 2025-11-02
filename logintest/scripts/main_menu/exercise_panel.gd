# exercise_panel.gd - CACHED VERSION
extends Control

# ============================================================================
# NODE REFERENCES
# ============================================================================
@onready var quiz_list = $LeftSideBar/MarginContainer/QuizList
@onready var quiz_content_label = $CenterDisplay/MarginContainer/ContentVBox/QuizContent
@onready var quiz_score_label = $CenterDisplay/MarginContainer/ContentVBox/QuizScore
@onready var attempt_info_label = $CenterDisplay/MarginContainer/ContentVBox/AttemptInfo
@onready var take_quiz_button = $CenterDisplay/MarginContainer/ContentVBox/TakeQuizButton

# ============================================================================
# PRELOADS
# ============================================================================
var QuizButtonScene = preload("res://scenes/main_menu/quiz_button.tscn")

# ============================================================================
# STATE VARIABLES
# ============================================================================
var _current_selected_quiz: Dictionary = {}
var _current_selected_button = null
var _is_setup: bool = false  # 🆕 Track if panel is already set up

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready():
	print("=== EXERCISE PANEL STARTING ===")
	
	if not quiz_list or not take_quiz_button:
		push_error("❌ Required nodes not found!")
		return
	
	print("✅ All nodes found!")
	
	# Set minimum size
	var button_height = 80
	var size_multiplier = 6
	quiz_list.custom_minimum_size.y = button_height * size_multiplier
	
	take_quiz_button.pressed.connect(_on_take_quiz_pressed)
	take_quiz_button.disabled = true
	
	# 🆕 Connect to QuizManager signals for live updates
	QuizManager.quiz_unlocked.connect(_on_quiz_unlocked)
	QuizManager.quiz_score_updated.connect(_on_quiz_score_updated)
	
	_clear_center_display()
	
	# 🆕 LOAD FROM CACHE if available, otherwise fetch from database
	_load_quizzes()

# ============================================================================
# DATA LOADING
# ============================================================================
func _load_quizzes():
	print("📚 Loading quiz data...")
	
	# 🆕 CHECK IF ALREADY SETUP - Don't reload unnecessarily
	if _is_setup and GameData.has_cached_progress():
		print("✅ Using existing setup (already loaded)")
		return
	
	if GameData.has_cached_progress():
		print("✅ Using cached level data")
		# Check if QuizManager has quiz scores loaded
		if QuizManager.quiz_scores.is_empty():
			print("⚠️ No quiz scores in QuizManager, loading from database...")
			Supabase.get_user_quiz_scores(Callable(self, "_on_quiz_scores_loaded"))
		else:
			print("✅ Using cached quiz scores")
			_setup_quiz_list()
			_is_setup = true
	else:
		print("⚠️ No cached data, loading from database...")
		Supabase.get_player_levels(Callable(self, "_on_levels_loaded"))

func _on_levels_loaded(data, code):
	print("📥 Levels loaded. Code: %d" % code)
	
	if code == 200 and data is Array:
		print("✅ Caching %d levels" % data.size())
		GameData.cache_progress(data)
		Supabase.get_user_quiz_scores(Callable(self, "_on_quiz_scores_loaded"))
	else:
		push_error("❌ Failed to load levels")

func _on_quiz_scores_loaded(data, code):
	print("📊 Quiz scores loaded. Code: %d" % code)
	
	if code == 200 and data is Array:
		print("✅ Loaded %d quiz score entries" % data.size())
		QuizManager.load_quiz_progress(data)
	else:
		print("⚠️ No quiz scores found yet")
	
	_setup_quiz_list()
	_is_setup = true  # 🆕 Mark as set up

# ============================================================================
# UI SETUP
# ============================================================================
func _setup_quiz_list():
	print("🔧 Setting up quiz button list...")
	
	# Clear existing buttons
	for child in quiz_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var levels = GameData.get_cached_progress()
	
	if levels.is_empty():
		push_error("❌ No levels available!")
		return
	
	print("✅ Creating buttons for %d levels" % levels.size())
	
	for level in levels:
		var level_id = level.get("id", "")
		if level_id.is_empty():
			continue
		
		var button = QuizButtonScene.instantiate()
		quiz_list.add_child(button)
		
		var is_unlocked = QuizManager.is_quiz_unlocked(level_id)
		var quiz_data = QuizManager.get_quiz_data(level_id)
		
		var button_data = {
			"level_id": level_id,
			"level_name": level.get("display_name", "Unknown Quiz"),
			"is_unlocked": is_unlocked,
			"score": quiz_data.get("best_score", 0),
			"total": quiz_data.get("total", 5),
			"attempts": quiz_data.get("attempts", 0)
		}
		
		button.setup(button_data)
		button.selected.connect(_on_quiz_selected.bind(button_data, button))
		button.deselected.connect(_on_quiz_deselected.bind(button))
	
	print("✅ Quiz list setup complete! Created %d buttons" % quiz_list.get_child_count())

# ============================================================================
# BUTTON INTERACTION
# ============================================================================
func _on_quiz_selected(quiz_data: Dictionary, button):
	if _current_selected_button and _current_selected_button != button:
		_current_selected_button.set_selected(false)
	
	_current_selected_button = button
	button.set_selected(true)
	_current_selected_quiz = quiz_data
	
	_update_center_display(quiz_data)
	
	if take_quiz_button:
		take_quiz_button.disabled = not quiz_data.is_unlocked

func _on_quiz_deselected(button):
	button.set_selected(false)
	_current_selected_button = null
	_current_selected_quiz = {}
	
	if take_quiz_button:
		take_quiz_button.disabled = true
	
	_clear_center_display()

# ============================================================================
# CENTER DISPLAY
# ============================================================================
func _update_center_display(quiz_data: Dictionary):
	if not quiz_content_label or not quiz_score_label or not attempt_info_label:
		return
	
	if quiz_data.is_unlocked:
		var best_score = quiz_data.get("score", 0)
		var total = quiz_data.get("total", 5)
		var percentage = (float(best_score) / float(total)) * 100.0 if total > 0 else 0.0
		
		quiz_content_label.text = "Quiz: %s" % quiz_data.get("level_name")
		quiz_score_label.text = "Best Score: %d/%d (%.0f%%)" % [best_score, total, percentage]
		
		if percentage >= 100.0:
			attempt_info_label.text = "✅ Perfect Score!"
			attempt_info_label.add_theme_color_override("font_color", Color.GREEN)
		elif percentage >= 80.0:
			attempt_info_label.text = "⭐ Great job!"
			attempt_info_label.add_theme_color_override("font_color", Color.YELLOW)
		elif percentage >= 60.0:
			attempt_info_label.text = "👍 Good effort!"
			attempt_info_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			attempt_info_label.text = "📚 Keep practicing!"
			attempt_info_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	else:
		quiz_content_label.text = "Quiz: %s" % quiz_data.get("level_name")
		quiz_score_label.text = "Status: 🔒 Locked"
		attempt_info_label.text = "Complete this quiz in-game first"
		attempt_info_label.add_theme_color_override("font_color", Color.GRAY)

func _clear_center_display():
	if quiz_content_label:
		quiz_content_label.text = "Select a quiz from the list"
	if quiz_score_label:
		quiz_score_label.text = ""
	if attempt_info_label:
		attempt_info_label.text = ""

# ============================================================================
# QUIZ INTERACTION
# ============================================================================
func _on_take_quiz_pressed():
	if _current_selected_quiz.is_empty() or not _current_selected_quiz.is_unlocked:
		return
	
	var level_id = _current_selected_quiz.get("level_id", "")
	if level_id.is_empty():
		return
	
	print("🎮 Loading quiz: %s" % level_id)
	Supabase.get_questions_for_level(level_id, Callable(self, "_on_questions_loaded"))

func _on_questions_loaded(data, code):
	if code != 200 or data.is_empty():
		push_error("❌ Failed to load questions")
		return
	
	var quiz_ui = get_tree().root.get_node_or_null("QuizUI")
	if quiz_ui:
		quiz_ui.show_quiz(data, _current_selected_quiz.level_id, true)
		if not quiz_ui.quiz_completed.is_connected(_on_quiz_completed_refresh):
			quiz_ui.quiz_completed.connect(_on_quiz_completed_refresh)

# ============================================================================
# LIVE UPDATES
# ============================================================================
func _on_quiz_completed_refresh(score: int, total: int):
	print("🎉 Quiz completed! Refreshing display...")
	_is_setup = false  # 🆕 Mark for refresh
	_load_quizzes()

func _on_quiz_unlocked(level_id: String):
	print("🔓 Quiz unlocked: %s" % level_id)
	_is_setup = false  # 🆕 Mark for refresh
	_load_quizzes()

func _on_quiz_score_updated(level_id: String, score: int, total: int):
	# 🆕 LIVE UPDATE: Just update the display if the selected quiz changed
	if _current_selected_quiz.get("level_id", "") == level_id:
		var updated_data = _current_selected_quiz.duplicate()
		updated_data.score = score
		updated_data.total = total
		_update_center_display(updated_data)
