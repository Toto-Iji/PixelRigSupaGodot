# SolutionItem.gd - Autoload Singleton
# Project → Project Settings → Autoload → Add this as "SolutionItem"

extends Node

# Types of solution items
enum ItemType {
	NONE,
	COMPONENT,  # CPU, RAM, GPU, etc - goes to terminal
	TOOL        # Fire extinguisher, wrench, etc - clears obstacles
}

# Current item player is carrying
var current_item: Dictionary = {
	"type": ItemType.NONE,
	"id": "",
	"name": "",
	"description": "",
	"icon": ""
}

signal item_received(item_data: Dictionary)
signal item_used(item_id: String)
signal item_deposited(item_id: String)

func has_item() -> bool:
	return current_item.type != ItemType.NONE

func get_current_item() -> Dictionary:
	return current_item

func receive_item(item_data: Dictionary) -> void:
	current_item = item_data
	item_received.emit(item_data)
	print("Received item:", item_data.name)

func use_item() -> void:
	if current_item.type == ItemType.TOOL:
		item_used.emit(current_item.id)
		print("Used tool:", current_item.name)
		# Tool is consumed after use
		clear_item()

func deposit_item() -> bool:
	if current_item.type == ItemType.COMPONENT:
		item_deposited.emit(current_item.id)
		print("Deposited component:", current_item.name)
		clear_item()
		return true
	return false

func clear_item() -> void:
	current_item = {
		"type": ItemType.NONE,
		"id": "",
		"name": "",
		"description": "",
		"icon": ""
	}

# -----------------------------------------------------------------------------
# 🆕 Helper functions for getting component/tool names
# -----------------------------------------------------------------------------
func get_component_name(component_id: String) -> String:
	var names = {
		"cpu": "Central Processing Unit",
		"ram": "RAM Module",
		"gpu": "Graphics Card",
		"motherboard": "Motherboard",
		"power_supply": "Power Supply",
		"hard_drive": "Hard Drive",
		"ssd": "Solid State Drive",
		"cooling_fan": "Cooling Fan",
		"network_card": "Network Card"
	}
	return names.get(component_id, "Unknown Component")

func get_tool_name(tool_id: String) -> String:
	var names = {
		"fire_extinguisher": "Fire Extinguisher",
		"wrench": "Wrench",
		"screwdriver": "Screwdriver",
		"multimeter": "Multimeter",
		"thermal_paste": "Thermal Paste",
		"antivirus": "Antivirus Software",
		"cable_tester": "Cable Tester"
	}
	return names.get(tool_id, "Unknown Tool")
