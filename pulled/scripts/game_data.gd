extends Node

var player_progress_data: Array = []
var is_progress_loaded: bool = false
var level_was_completed: bool = false  # Track if we need to refetch
var player_components_data: Array = []
var is_components_loaded: bool = false
var current_component: Dictionary = {}  # For passing data between scenes

func cache_progress(data: Array):
	player_progress_data = data
	is_progress_loaded = true
	level_was_completed = false  # Reset after caching
	print("Progress cached:", data)

# LEVEL PROGRESS FETCHING
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
	
# COMPONENT PROGRESS FETCHING
func cache_components(data: Array):
	player_components_data = data
	is_components_loaded = true
	print("Components cached:", data)

func get_cached_components() -> Array:
	return player_components_data

func has_cached_components() -> bool:
	return is_components_loaded

func set_current_component(component_data: Dictionary):
	"""Store component for quiz/minigame scenes"""
	current_component = component_data

func get_current_component() -> Dictionary:
	return current_component

func clear_current_component():
	current_component = {}
