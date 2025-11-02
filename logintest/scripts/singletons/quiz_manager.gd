# quiz_manager.gd - Autoload Singleton
extends Node

var unlocked_quizzes: Dictionary = {}
var quiz_scores: Dictionary = {}

signal quiz_unlocked(level_id: String)
signal quiz_score_updated(level_id: String, score: int, total: int)

func _ready():
	unlocked_quizzes = {
		"part_1": false,
		"part_2": false,
		"part_3": false,
		"part_4": false,
		"part_5": false,
		"part_6": false,
	}
	quiz_scores = {}

func unlock_quiz(level_id: String):
	if unlocked_quizzes.has(level_id):
		unlocked_quizzes[level_id] = true
		quiz_unlocked.emit(level_id)
		print("✅ Quiz unlocked: ", level_id)

func is_quiz_unlocked(level_id: String) -> bool:
	return unlocked_quizzes.get(level_id, false)

func update_quiz_score(level_id: String, score: int, total: int):
	if not quiz_scores.has(level_id):
		# First attempt
		quiz_scores[level_id] = {
			"score": score,
			"total": total,
			"attempts": 1,
			"best_score": score
		}
	else:
		# Subsequent attempts
		var current = quiz_scores[level_id]
		current.attempts += 1
		
		# 🆕 ONLY update best_score if new score is HIGHER
		if score > current.best_score:
			current.best_score = score
			print("🎉 NEW HIGH SCORE: %d/%d!" % [score, total])
		else:
			print("Previous best: %d, Current: %d (kept best)" % [current.best_score, score])
		
		# 🆕 Always update current score (for "last attempt" tracking if needed)
		current.score = score
		current.total = total
	
	quiz_score_updated.emit(level_id, score, total)
	print("📊 Quiz score updated: %s - %d/%d (Best: %d)" % [level_id, score, total, quiz_scores[level_id].best_score])

func get_quiz_data(level_id: String) -> Dictionary:
	return quiz_scores.get(level_id, {})

func load_quiz_progress(data: Array):
	# Group quiz scores by level_id and count attempts
	var level_attempts = {}
	var level_best_scores = {}
	
	for entry in data:
		var level_id = entry.get("level_id", "")
		if level_id.is_empty():
			continue
		
		# Mark as unlocked
		if unlocked_quizzes.has(level_id):
			unlocked_quizzes[level_id] = true
		
		# Count attempts
		if not level_attempts.has(level_id):
			level_attempts[level_id] = 0
		level_attempts[level_id] += 1
		
		# Track best score
		var score = entry.get("score", 0)
		var total = entry.get("total_questions", 5)
		
		if not level_best_scores.has(level_id):
			level_best_scores[level_id] = {"score": score, "total": total}
		else:
			if score > level_best_scores[level_id].score:
				level_best_scores[level_id] = {"score": score, "total": total}
	
	# Update quiz_scores with aggregated data
	for level_id in level_attempts.keys():
		quiz_scores[level_id] = {
			"score": level_best_scores[level_id].score,
			"total": level_best_scores[level_id].total,
			"attempts": level_attempts[level_id],
			"best_score": level_best_scores[level_id].score
		}
	
	print("📚 Loaded quiz progress for %d quizzes" % quiz_scores.size())
	for level_id in quiz_scores.keys():
		var data_entry = quiz_scores[level_id]
		print("  📊 %s: %d/%d (%d attempts)" % [level_id, data_entry.score, data_entry.total, data_entry.attempts])
