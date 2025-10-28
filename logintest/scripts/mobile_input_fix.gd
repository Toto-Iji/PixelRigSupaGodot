extends Node

# Call this when you need mobile-friendly text input
func get_text_input(placeholder: String, is_password: bool, callback: Callable):
	if OS.has_feature("web"):
		var js_code = """
		var input = prompt('%s');
		if (input !== null) {
			return input;
		}
		return '';
		""" % placeholder
		
		var result = JavaScriptBridge.eval(js_code)
		callback.call(str(result))
	else:
		# Desktop - use normal LineEdit
		callback.call("")
