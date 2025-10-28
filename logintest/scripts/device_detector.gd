extends Node

var is_mobile: bool = false
var has_touchscreen: bool = false

func _ready():
	_detect_device()

func _detect_device():
	print("🔍 DEVICE DETECTION START")
	
	# Check 1: Touchscreen
	has_touchscreen = DisplayServer.is_touchscreen_available()
	print("📱 Touchscreen available: ", has_touchscreen)
	
	# Check 2: Platform features
	print("🖥️ Platform features:")
	print("  - web: ", OS.has_feature("web"))
	print("  - mobile: ", OS.has_feature("mobile"))
	print("  - pc: ", OS.has_feature("pc"))
	
	# Check 3: User agent (if web)
	if OS.has_feature("web"):
		var ua = JavaScriptBridge.eval("navigator.userAgent")
		print("🌐 User Agent: ", ua)
		
		if typeof(ua) == TYPE_STRING:
			var ua_lower = ua.to_lower()
			is_mobile = (
				"android" in ua_lower or
				"iphone" in ua_lower or
				"ipad" in ua_lower or
				"mobile" in ua_lower
			)
			print("📱 Is mobile (by UA): ", is_mobile)
	else:
		# Native builds
		is_mobile = OS.has_feature("mobile")
		print("📱 Is mobile (native): ", is_mobile)
	
	print("✅ FINAL RESULT:")
	print("  - Is Mobile: ", is_mobile)
	print("  - Has Touchscreen: ", has_touchscreen)
	print("  - Show Controls: ", should_show_mobile_controls())

func should_show_mobile_controls() -> bool:
	# BOTH conditions must be true
	return is_mobile and has_touchscreen

func is_mobile_device() -> bool:
	return is_mobile

func is_touchscreen_device() -> bool:
	return has_touchscreen
