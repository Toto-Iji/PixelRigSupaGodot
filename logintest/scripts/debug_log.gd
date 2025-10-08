extends Node

signal log_updated(message)


func logv(args: Array):
	var message_parts: Array[String] = []
	for arg in args:
		message_parts.append(str(arg))
	
	var final_message = " ".join(message_parts)
	
	print(final_message)
	
	var formatted_message = "> " + final_message
	log_updated.emit(formatted_message)
