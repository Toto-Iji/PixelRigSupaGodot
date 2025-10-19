extends Node

var player_progress_data: Array = []
var is_progress_loaded: bool = false
var level_was_completed: bool = false  # Track if we need to refetch

func cache_progress(data: Array):
	player_progress_data = data
	is_progress_loaded = true
	level_was_completed = false  # Reset after caching
	print("Progress cached:", data)

func get_cached_progress() -> Array:
	return player_progress_data

func has_cached_progress() -> bool:
	return is_progress_loaded

func mark_level_completed():
	"""Call this when player completes a level"""
	level_was_completed = true
	print("Level completed, will refetch on return to menu")

func should_refetch() -> bool:
	return level_was_completed

func clear_cache():
	player_progress_data = []
	is_progress_loaded = false
	level_was_completed = false
