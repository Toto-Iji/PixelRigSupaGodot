# tool.gd
extends Area2D

@export var tool_name = "Demo Tool"
@export var is_level_completion_item = true  # Mark if this completes the level
var indicator: Node = null

func _ready():
	var indicator_scene = preload("res://scenes/game/indicator.tscn")
	indicator = indicator_scene.instantiate()
	indicator.position = Vector2(0, -32)
	add_child(indicator)

func interact():
	# Give item to player
	SolutionItem.receive_item({
		"type": SolutionItem.ItemType.COMPONENT,
		"id": tool_name.to_lower().replace(" ", "_"),
		"name": tool_name,
		"description": "A critical component.",
		"icon": "res://icons/component.png"
	})
	
	# Show pickup message if UI manager exists
	var ui_manager = get_tree().get_root().get_node_or_null("World/UI")
	if ui_manager and ui_manager.has_method("show_message"):
		ui_manager.show_message("Picked up " + tool_name)
	
	# Trigger level completion if this is the final item
	if is_level_completion_item:
		var world = get_tree().get_root().get_node_or_null("World")
		if world and world.has_method("show_level_complete"):
			world.show_level_complete()
	
	queue_free()
