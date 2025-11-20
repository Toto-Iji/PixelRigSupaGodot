extends CanvasLayer

# --- CHECK THIS LINE ---
signal dialogue_finished
# -----------------------

@onready var text_label = $Control/DialoguePanel/MarginContainer/RichTextLabel
@onready var dialogue_panel = $Control/DialoguePanel
@onready var control_root = $Control

var dialogue_queue: Array[String] = []
var is_typing: bool = false
var current_index: int = 0
var char_timer: float = 0.0
const TYPE_SPEED: float = 0.02

func _ready():
	control_root.visible = false
	print("DEBUG: DialogueLayer is Ready")

func _process(delta):
	if is_typing:
		if text_label.visible_ratio < 1.0:
			char_timer += delta
			if char_timer >= TYPE_SPEED:
				char_timer = 0.0
				text_label.visible_characters += 1
		else:
			is_typing = false

func start_dialogue(lines: Array[String]):
	print("DEBUG: start_dialogue called with ", lines.size(), " lines")
	
	# --- FAIL SAFE FIX ---
	if lines.is_empty():
		print("DEBUG: No text found! Emitting finished signal immediately to unfreeze player.")
		emit_signal("dialogue_finished") 
		return
	# ---------------------
	
	dialogue_queue = lines
	current_index = 0
	show_dialogue()
	_display_current_line()

func show_dialogue():
	print("DEBUG: Dialogue GUI opened")
	control_root.visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS 

func hide_dialogue():
	print("DEBUG: hide_dialogue called")
	control_root.visible = false
	dialogue_queue.clear()
	
	print("DEBUG: Attempting to emit 'dialogue_finished'...")
	emit_signal("dialogue_finished") 
	print("DEBUG: Signal emitted!")

func _display_current_line():
	if dialogue_queue.is_empty(): return
	
	var line = dialogue_queue[current_index]
	# print("DEBUG: Displaying line: " + line) 
	text_label.text = line
	
	text_label.visible_characters = 0
	text_label.visible_ratio = 0.0
	is_typing = true
	
	await get_tree().process_frame
	dialogue_panel.reset_size() 

func _input(event):
	if not control_root.visible:
		return

	if event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		
		if is_typing:
			text_label.visible_ratio = 1.0
			is_typing = false
		else:
			current_index += 1
			if current_index < dialogue_queue.size():
				_display_current_line()
			else:
				print("DEBUG: End of text reached, calling hide_dialogue")
				hide_dialogue()
