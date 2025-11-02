# quiz_cache.gd - Autoload Singleton
extends Node

var cached_questions: Dictionary = {}
var loading_states: Dictionary = {}

signal questions_loaded(level_id: String, questions: Array)
signal questions_failed(level_id: String)

func preload_questions(level_id: String):
	if cached_questions.has(level_id):
		print("✅ Questions already cached for:", level_id)
		return
	
	if loading_states.get(level_id, false):
		print("⏳ Already loading questions for:", level_id)
		return
	
	loading_states[level_id] = true
	print("📚 Preloading questions for:", level_id)
	Supabase.get_questions_for_level(level_id, Callable(self, "_on_questions_loaded").bind(level_id))

func _on_questions_loaded(data, code, level_id: String):
	loading_states[level_id] = false
	
	if code != 200:
		push_error("❌ Failed to preload questions for %s. Code: %d" % [level_id, code])
		questions_failed.emit(level_id)
		return
	
	if data.is_empty():
		push_error("❌ No questions found for level: %s" % level_id)
		questions_failed.emit(level_id)
		return
	
	cached_questions[level_id] = data
	print("✅ Cached %d questions for: %s" % [data.size(), level_id])
	questions_loaded.emit(level_id, data)

func get_questions(level_id: String) -> Array:
	return cached_questions.get(level_id, [])

func has_questions(level_id: String) -> bool:
	return cached_questions.has(level_id)

func clear_cache():
	cached_questions.clear()
	loading_states.clear()
