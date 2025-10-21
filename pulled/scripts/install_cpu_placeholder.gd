extends Control

func _ready():
	$VBoxContainer/Label.text = "CPU Installation Minigame\n(Placeholder - Gameplay devs implement this)"
	$VBoxContainer/CompleteButton.pressed.connect(_on_complete_pressed)

func _on_complete_pressed():
	var component = GameData.get_current_component()
	
	# Mark as installed
	Supabase.install_component(component.id, func(data, code):
		if code == 200:
			print("Component installed!")
			GameData.clear_current_component()
			# Trigger refetch of components
			GameData.cache_components([])  # Clear cache to force reload
			get_tree().change_scene_to_file("res://scenes/main_menu_screen.tscn")
	)
