extends HBoxContainer

# Map each component to its minigame scene path
var minigame_paths = {
	"CPU": "res://mini-game/MiniGames/scenes/mini_game.tscn",
	"RAM": "res://mini-game/MiniGames/scenes/mini_game_ram.tscn",
	"GPU": "res://mini-game/MiniGames/scenes/mini_game_gpu.tscn",
	"Motherboard": "res://mini-game/MiniGames/scenes/mini_game_motherboard.tscn",
	"PSU": "res://mini-game/MiniGames/scenes/mini_game_psu.tscn",
	"Storage": "res://mini-game/MiniGames/scenes/mini_game_storage.tscn"
}

# Node references
@onready var component_list = $LeftSideBar/ScrollContainer/ComponentList
@onready var progress_label = $CenterDisplay/ProgressInfo/ProgressLabel
@onready var instruction_label = $CenterDisplay/ProgressInfo/InstructionLabel

var completed_components = []

func _ready():
	print("🔧 BuildPanel ready!")
	if progress_label:
		progress_label.text = "Progress: 0/6 components installed"
	if instruction_label:
		instruction_label.text = "Select a component from the list to begin"
	_setup_component_list()

func _setup_component_list():
	if not component_list:
		return
	for child in component_list.get_children():
		child.queue_free()
	var components = ["CPU", "RAM", "GPU", "Motherboard", "PSU", "Storage"]
	for comp in components:
		var btn = Button.new()
		btn.text = comp
		btn.custom_minimum_size = Vector2(150, 40)
		if comp in completed_components:
			btn.text = "✅ " + comp
			btn.disabled = true
		btn.pressed.connect(_on_component_selected.bind(comp))
		component_list.add_child(btn)

func _on_component_selected(component_name: String):
	print("🎯 Selected component:", component_name)
	if instruction_label:
		instruction_label.text = "Loading " + component_name + " installation..."

	if minigame_paths.has(component_name):
		_start_transition_to_minigame(minigame_paths[component_name])
	else:
		if instruction_label:
			instruction_label.text = component_name + " minigame coming soon!"

func _start_transition_to_minigame(scene_path):
	# Optional: use a transition effect scene (recommended)
	if ResourceLoader.exists("res://scenes/transition_scene.tscn"):
		var transition = preload("res://scenes/transition_scene.tscn").instantiate()
		get_tree().root.add_child(transition)
		transition.start_transition(scene_path)
	else:
		# Instant change if you have no transition scene
		get_tree().change_scene_to_file(scene_path)

# You can add progress/completion saving logic as needed!
