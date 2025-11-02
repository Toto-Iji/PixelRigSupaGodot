extends HBoxContainer

@onready var component_list = $LeftSideBar/ScrollContainer/ComponentList
@onready var progress_label = $CenterDisplay/ProgressInfo/ProgressLabel
@onready var instruction_label = $CenterDisplay/ProgressInfo/InstructionLabel

var _components_data: Array = []

func _ready():
	instruction_label.text = "Loading components..."
	_load_components()

func _load_components():
	Supabase.get_player_components(Callable(self, "_on_components_loaded"))

func _on_components_loaded(data, code):
	if code != 200:
		instruction_label.text = "❌ Failed to load components."
		push_error("ComponentScreen: Load failed - Code: %d" % code)
		return
	
	_components_data = data
	
	if _components_data.is_empty():
		instruction_label.text = "No components available yet."
		progress_label.text = "Progress: 0/0 Components"
		return
	
	_setup_component_list()
	_update_progress()
	instruction_label.text = "Press SPACE to collect next component (for testing)"

func _setup_component_list():
	# Clear existing buttons
	for child in component_list.get_children():
		child.queue_free()
	
	# Create buttons for each component
	for component in _components_data:
		var button = _create_component_button(component)
		component_list.add_child(button)

func _create_component_button(component: Dictionary) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 60)
	button.text = "%s\n%s" % [component.name, component.category]
	
	# Style based on status
	if component.installed:
		button.modulate = Color(0.7, 1.0, 0.7)  # Green
		button.text += " ✅ Installed"
		button.disabled = true
	elif component.collected:
		button.modulate = Color(1, 1, 0.7)  # Yellow
		button.text += " 🎮 Ready to Install"
		button.pressed.connect(_on_install_clicked.bind(component))
	else:
		button.modulate = Color(0.5, 0.5, 0.5)  # Gray
		button.text += " 🔒 Locked"
		button.disabled = true
	
	return button

func _on_install_clicked(component: Dictionary):
	instruction_label.text = "Installing %s..." % component.name
	
	Supabase.install_component_debug(component.id, func(data, code):
		if code == 200:
			instruction_label.text = "✅ %s installed!" % component.name
			_load_components()  # Refresh
		else:
			instruction_label.text = "❌ Installation failed."
			push_error("ComponentScreen: Installation failed - Code: %d" % code)
	)

func _update_progress():
	var total = _components_data.size()
	var installed = 0
	
	for component in _components_data:
		if component.installed:
			installed += 1
	
	progress_label.text = "Progress: %d/%d Components Installed" % [installed, total]

# DEBUG: Press SPACE to collect next locked component
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		for component in _components_data:
			if not component.collected:
				_collect_component(component.id)
				return
		instruction_label.text = "All components already collected!"

func _collect_component(component_id: String):
	instruction_label.text = "Collecting component..."
	
	Supabase.collect_component_debug(component_id, func(data, code):
		if code == 200:
			instruction_label.text = "🎁 Component collected!"
			_load_components()  # Refresh
		else:
			instruction_label.text = "❌ Collection failed."
			push_error("ComponentScreen: Collection failed - Code: %d" % code)
	)
