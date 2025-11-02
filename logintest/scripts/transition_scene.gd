# transition_scene.gd
extends CanvasLayer

@onready var animation_player = $AnimationPlayer

var _target_scene_path = ""

func _ready():
	# Validate that AnimationPlayer exists
	if not animation_player:
		push_error("TransitionScene: AnimationPlayer node not found. Check node path.")

func start_transition(target_scene_path: String):
	"""
	Starts the transition process.
	1. Stores the target path.
	2. Plays the fade_to_black animation.
	"""
	if target_scene_path.is_empty():
		push_error("TransitionScene: Cannot start transition with empty scene path.")
		queue_free()
		return
	
	if not animation_player:
		push_error("TransitionScene: AnimationPlayer not available.")
		queue_free()
		return
	
	_target_scene_path = target_scene_path
	
	# Start the first animation (fades to full black)
	animation_player.play("fade_to_black")
	
	# Connect to the signal that tells us when this animation is done
	if not animation_player.animation_finished.is_connected(_on_fade_to_black_finished):
		animation_player.animation_finished.connect(_on_fade_to_black_finished)
	
func _on_fade_to_black_finished(anim_name: String):
	"""
	Called when 'fade_to_black' finishes.
	The screen is now fully covered, so it's safe to change the scene.
	"""
	if anim_name != "fade_to_black":
		return
	
	# Disconnect the signal to avoid errors when changing scene
	if animation_player.animation_finished.is_connected(_on_fade_to_black_finished):
		animation_player.animation_finished.disconnect(_on_fade_to_black_finished)
	
	if _target_scene_path.is_empty():
		push_error("TransitionScene: Target scene path is empty.")
		queue_free()
		return
	
	# Attempt scene change
	var error = get_tree().change_scene_to_file(_target_scene_path)
	if error != OK:
		push_error("TransitionScene: Failed to change scene to '%s'. Error code: %d" % [_target_scene_path, error])
		queue_free()
		return
	
	# After the scene changes, the transition instance persists into the new scene
	# Connect the signal for the second animation
	if not animation_player.animation_finished.is_connected(_on_fade_to_normal_finished):
		animation_player.animation_finished.connect(_on_fade_to_normal_finished)
	
	# Start the second animation (fades back to normal/transparent)
	animation_player.play("fade_to_normal")

func _on_fade_to_normal_finished(anim_name: String):
	"""
	Called when 'fade_to_normal' finishes.
	The transition is complete, and the scene is revealed.
	"""
	if anim_name == "fade_to_normal":
		# Remove the transition scene from the tree, as its job is done
		queue_free()
