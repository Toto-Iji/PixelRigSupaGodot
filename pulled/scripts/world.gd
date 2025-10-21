# world.gd
extends Node2D

# --- NEW: Pause Menu Definitions ---
const PAUSE_MENU_SCENE = preload("res://scenes/pause_menu.tscn")
const MAIN_MENU_PATH = "res://scenes/main_menu_screen.tscn"
const MOBILE_CONTROLS_SCENE = preload("res://scenes/mobile_controls.tscn")
var mobile_controls = null
var is_paused_active = false
var current_pause_menu = null
# -----------------------------------

var spawn_point: Vector2

@onready var player = $Player
@onready var hud = $CanvasLayer/HUD
@onready var death_popup = $CanvasLayer/DeathPopup if has_node("CanvasLayer/DeathPopup") else null
@onready var dialogue_system = $DialogueSystem if has_node("DialogueSystem") else null
@onready var collection_popup = $CanvasLayer/CollectionPopup if has_node("CanvasLayer/CollectionPopup") else null
@onready var level_manager = $LevelManager if has_node("LevelManager") else null
@onready var tutorial_popup = $CanvasLayer/TutorialPopup if has_node("CanvasLayer/TutorialPopup") else null
@onready var level_complete_popup = $CanvasLayer/LevelCompletePopup if has_node("CanvasLayer/LevelCompletePopup") else null

func _ready():
	# --- Existing Connections ---
	player.health_changed.connect(hud.update_health)
	
	if death_popup:
		death_popup.respawn_requested.connect(respawn_player)
		death_popup.main_menu_requested.connect(_on_main_menu_requested)
	
	if dialogue_system:
		dialogue_system.dialogue_finished.connect(_on_intro_dialogue_finished)
	
	if collection_popup:
		collection_popup.continue_pressed.connect(_on_collection_continue)
	
	if level_manager:
		level_manager.component_collected.connect(_on_component_collected)
	
	if tutorial_popup:
		tutorial_popup.lets_go_pressed.connect(_on_tutorial_finished)
	
	if level_complete_popup:
		level_complete_popup.next_level_pressed.connect(_on_next_level)
		level_complete_popup.main_menu_pressed.connect(_on_main_menu_requested)
	
	# Initialize HUD and Spawn Point
	hud.update_health(player.health)
	
	if has_node("PlayerStart"):
		var player_start = $PlayerStart
		spawn_point = player_start.global_position
	else:
		spawn_point = player.global_position
	
	player.global_position = spawn_point
	
	# 🆕 ADD MOBILE CONTROLS
	_setup_mobile_controls()
	
	# Start intro cutscene
	start_intro_cutscene()

# -----------------------------------------------------------------------------
# 🆕 NEW: Input Handling for Pause Menu
# -----------------------------------------------------------------------------

func _input(event):
	# Check for the Escape key press (mapped to "ui_cancel" by default)
	if event.is_action_pressed("ui_cancel"):
		# Ensure we don't pause if any critical popups are open (e.g., Death/Complete)
		if death_popup and death_popup.visible:
			return
		if level_complete_popup and level_complete_popup.visible:
			return
			
		if is_paused_active:
			# If the menu is already open, rely on the menu script to unpause/close itself
			pass 
		else:
			# If the game is running, open the pause menu
			open_pause_menu()
		
		get_viewport().set_input_as_handled()

func open_pause_menu():
	if is_paused_active:
		return # Prevent opening multiple menus
	
	# 1. Pause the entire game tree
	get_tree().paused = true
	is_paused_active = true
	
	# 2. Instantiate and add the menu
	current_pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(current_pause_menu)
	
	# 3. Connect signals from the menu to handle actions
	current_pause_menu.continue_pressed.connect(_on_pause_menu_continue)
	current_pause_menu.restart_pressed.connect(_on_pause_menu_restart)
	current_pause_menu.main_menu_pressed.connect(_on_pause_menu_main_menu)

# -----------------------------------------------------------------------------
# 🆕 NEW: Pause Menu Signal Handlers
# -----------------------------------------------------------------------------

func _on_pause_menu_continue():
	# 🟢 CONTINUE: The menu script already unpaused and queued itself for deletion.
	is_paused_active = false
	current_pause_menu = null
	# The game continues

func _on_pause_menu_restart():
	get_tree().paused = false
	is_paused_active = false

	# Create and play transition
	var transition = preload("res://scenes/transition_scene.tscn").instantiate()
	add_child(transition)

	# Restart the current scene with a smooth fade
	var current_scene_path = get_tree().current_scene.scene_file_path
	transition.start_transition(current_scene_path)

	# Clean up the pause menu
	if current_pause_menu:
		current_pause_menu.queue_free()
	current_pause_menu = null



func _on_pause_menu_main_menu():
	# 🏠 MAIN MENU:
	# 1. Unpause the game BEFORE changing the scene
	get_tree().paused = false
	is_paused_active = false
	
	# 2. Change scene to the main menu
	print("🏠 Returning to main menu:", MAIN_MENU_PATH)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
	


# -----------------------------------------------------------------------------
# 🛠️ MODIFIED: Existing Functions
# -----------------------------------------------------------------------------
func _setup_mobile_controls():
	# Show controls only if device truly has a touchscreen
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"):
		mobile_controls = MOBILE_CONTROLS_SCENE.instantiate()
		add_child(mobile_controls)
		print("📱 Mobile controls added (touchscreen detected)")
	else:
		print("💻 Touchscreen not detected — mobile controls hidden")


func _on_main_menu_requested():
	# This function is used by the Death and Level Complete popups.
	# We ensure the game is unpaused before leaving the scene.
	get_tree().paused = false
	
	print("🏠 Going to main menu (from popup):", MAIN_MENU_PATH)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


# --- (The rest of your existing functions remain the same) ---

func respawn_player():
# ... (contents unchanged) ...
	# 🔹 Freeze player immediately
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	# 🔹 Reset all hostiles first (and wait for them to finish)
	await reset_all_hostiles()
	
	# 🔹 Respawn player with collision disabled temporarily
	if player.has_method("respawn_at"):
		await player.respawn_at(spawn_point)
	else:
		# Fallback if respawn_at method doesn't exist
		player.global_position = spawn_point
		player.health = player.max_health
		player.velocity = Vector2.ZERO
		if player.has_method("clear_knockback"):
			player.clear_knockback()
	
	# 🔹 Re-enable player physics
	player.set_physics_process(true)
	
	# 🔹 Update HUD to show full hearts again
	hud.update_health(player.health)
	
	print("🔄 Respawned at:", spawn_point)

func reset_all_hostiles():
# ... (contents unchanged) ...
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	
	print("🔄 Starting reset of", hostiles.size(), "hostiles...")
	
	# Call reset_state on all hostiles
	for hostile in hostiles:
		if hostile and hostile.has_method("reset_state"):
			hostile.reset_state()
	
	# Wait for them all to finish (0.1 seconds + a bit extra)
	await get_tree().create_timer(0.15).timeout
	
	print("✅ All hostiles reset complete!")

func set_spawn_point(new_point: Vector2):
# ... (contents unchanged) ...
	spawn_point = new_point

func show_death_popup():
# ... (contents unchanged) ...
	if death_popup:
		death_popup.show_popup()
	else:
		print("⚠️ DeathPopup not found! Auto-respawning...")
		# Fallback: just respawn after a delay
		await get_tree().create_timer(1.0).timeout
		respawn_player()

# 🎬 Intro Cutscene System
func start_intro_cutscene():
# ... (contents unchanged) ...
	if not dialogue_system:
		print("⚠️ No DialogueSystem found, skipping intro")
		return
	
	# Disable player control during cutscene
	player.set_physics_process(false)
	
	# 🔹 NEW: Freeze all hostiles during cutscene
	freeze_all_hostiles()
	
	# Define your intro dialogue with camera pans
	var intro_dialogue = [
		{
			"speaker": "System Alert",
			"text": "Warning! The motherboard is under attack by malware!",
			"camera_target": $hostile.global_position,# Pan to hostile/problem area
			"pan_duration": 1.5
		},
		{
			"speaker": "System Alert",
			"text": "Critical system files are corrupted and need immediate repair!",
			"camera_target": $Tool.global_position,# Pan to another danger area
			"pan_duration": 1.0
		},
		{
			"speaker": "AI Assistant",
			"text": "You must navigate through the PC and eliminate all threats!",
			"camera_target": player.global_position,# Pan back to player
			"pan_duration": 1.2
		}
	]
	
	dialogue_system.start_dialogue(intro_dialogue)

func _on_intro_dialogue_finished():
# ... (contents unchanged) ...
	# Re-enable player control after cutscene
	player.set_physics_process(true)
	
	# 🔹 NEW: Unfreeze all hostiles
	unfreeze_all_hostiles()
	
	print("✅ Intro cutscene finished - Game started!")

# 🔹 NEW: Freeze/Unfreeze hostile functions
func freeze_all_hostiles():
# ... (contents unchanged) ...
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	for hostile in hostiles:
		if hostile:
			hostile.set_physics_process(false)
			if hostile.has_node("AnimatedSprite2D"):
				hostile.get_node("AnimatedSprite2D").stop()

func unfreeze_all_hostiles():
# ... (contents unchanged) ...
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	for hostile in hostiles:
		if hostile:
			hostile.set_physics_process(true)

# Level Complete System
func show_level_complete():
# ... (contents unchanged) ...
	if level_complete_popup:
		var component = SolutionItem.get_current_item()
		level_complete_popup.show_completion(component.get("name", "Component"))
	else:
		print("LEVEL COMPLETE!")

func _on_next_level():
# ... (contents unchanged) ...
	# TODO: Load next level
	print("Going to next level...")
	# get_tree().change_scene_to_file("res://Level2.tscn")

# 🎁 Component Collection System
func show_collection_popup(component_id: String):
# ... (contents unchanged) ...
	if collection_popup:
		player.set_physics_process(false)# Freeze player during popup
		collection_popup.show_collection(component_id)
	else:
		print("⚠️ No collection popup found!")

func _on_component_collected(component_id: String):
# ... (contents unchanged) ...
	print("🎉 Component collected:", component_id)

func _on_collection_continue():
# ... (contents unchanged) ...
	player.set_physics_process(true) # Unfreeze player

func _on_tutorial_finished():
# ... (contents unchanged) ...
	if tutorial_popup:
		tutorial_popup.hide()
	
	# Unfreeze the player and re-enable game actions
	player.set_physics_process(true)
	unfreeze_all_hostiles()
	
	print("✅ Tutorial finished - Game fully started!")
	# Go to next level if available
	if level_manager and level_manager.next_level_scene != "":
		level_manager.go_to_next_level()
	else:
		print("✅ Level completed! (No next level set)")
