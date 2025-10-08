extends CanvasLayer

@onready var log_text_label = $PanelContainer/MarginContainer/LogText


static var accumulated_logs: String = ""

func _ready():

	hide()
	

	if not accumulated_logs.is_empty():
		log_text_label.text = accumulated_logs
	

	if not DebugLog.log_updated.is_connected(_on_log_updated):
		DebugLog.log_updated.connect(_on_log_updated)

func _input(event):
	if event.is_action_pressed("toggle_console"):
		visible = not visible

func _on_log_updated(new_message):
	var formatted_line = new_message + "\n"
	

	log_text_label.append_text(formatted_line)
	

	accumulated_logs += formatted_line
