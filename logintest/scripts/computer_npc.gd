extends StaticBody2D

@onready var dialogue_ui = $DialogueLayer

# 🔗 Drag your SlidingDoor node here in the Inspector
@export var linked_door: Node2D 

# We DO NOT use @export for text to prevent Inspector bugs
var story_lines: Array[String] = [
	"You noticed a PC on top of the desk... powering on.",
	"Welcome back, Professor Ad— wait. You’re... not him. Interesting. You have his eyes, though. You must be his grandchild.",
	"Professor Francis Adler. Founder of the Mind Sync System. It’s been twenty years since he last logged into this tester account.",
	"He built all of this, you know — PixelRig, the entire learning framework, every module, every tool. Looks like you inherited his problem-solving skills.",
	"If you found this device in a hidden room, then he wanted someone like you to discover it. The system you’ve synced with contains everything about computers — how they work, how to assemble them, how to truly understand them.",
	"If you're ready... I can show you around."
]

var unlocked_lines: Array[String] = [
	"Access granted. You can now proceed to the next room."
]

var has_unlocked_door: bool = false
var player_ref = null

func _ready():
	if has_node("DialogueLayer"):
		dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)
	
	# Debug Check
	if linked_door == null:
		print("❌ CRITICAL ERROR: 'Linked Door' is empty! Click ComputerNPC in the scene and assign the Door node.")
	else:
		print("✅ NPC connected to door: ", linked_door.name)

func interact():
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("Player")
	
	if player_ref:
		player_ref.can_move = false
		player_ref.can_shoot = false
		player_ref.velocity = Vector2.ZERO
	
	# Send the correct text
	if has_unlocked_door:
		print("sending unlocked lines: ", unlocked_lines.size())
		dialogue_ui.start_dialogue(unlocked_lines)
	else:
		print("sending story lines: ", story_lines.size())
		dialogue_ui.start_dialogue(story_lines)

func _on_dialogue_finished():
	if player_ref:
		player_ref.can_move = true
		player_ref.can_shoot = true
	
	if not has_unlocked_door:
		has_unlocked_door = true
		print("🔓 Attempting to unlock door...")
		
		if linked_door:
			if linked_door.has_method("unlock_door"):
				linked_door.unlock_door()
				# Force an update in case player is standing in it
				_update_door_state()
			else:
				print("❌ ERROR: The linked node exists but does not have 'unlock_door()'. Check sliding_door.gd script.")
		else:
			print("❌ ERROR: Cannot unlock. 'Linked Door' is NULL.")

# Helper to handle if player is already standing at the door
func _update_door_state():
	if linked_door.has_method("_on_area_body_entered") and player_ref:
		# We simulate the player entering the door area again to trigger the open
		var door_area = linked_door.get_node_or_null("Area2D")
		if door_area and door_area.overlaps_body(player_ref):
			linked_door._open_door()
