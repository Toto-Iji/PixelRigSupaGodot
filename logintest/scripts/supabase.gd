extends Node

# ---! CONFIGURATION !---
const SUPABASE_URL = "https://zrilkyxisplfanzloauu.supabase.co"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpyaWxreXhpc3BsZmFuemxvYXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4MjE3NTUsImV4cCI6MjA3MzM5Nzc1NX0.7EoKEemphqyTZ7YAbXJF3EKqrxahXWpz8yLu_k-iSiY"
const SAVE_FILE_PATH = "user://auth_data.save"
# -----------------------

# --- VARIABLES ---
var access_token: String = ""
var refresh_token: String = ""
var current_user: Dictionary = {}

# --- DEFAULT HEADERS ---
func _get_default_headers() -> Array[String]:
	var headers: Array[String] = [
		"apikey: " + SUPABASE_KEY,
		"Content-Type: application/json",
		"Accept-Encoding: identity" #
	]
	if not access_token.is_empty():
		headers.append("Authorization: Bearer " + access_token)
	return headers

# --- HELPER: SEND REQUEST ---
func _do_request(path: String, method: int, body: Dictionary, callback: Callable, extra_headers: Array = []):
	var http_request = HTTPRequest.new()
	http_request.accept_gzip = false
	http_request.use_threads = false
	add_child(http_request)
	
	# Force no compression by adding header preference
	var url = SUPABASE_URL + path
	
	var headers = _get_default_headers()
	# Remove any existing Accept-Encoding
	headers = headers.filter(func(h): return not "Accept-Encoding" in h)
	# Add identity ONLY
	headers.append("Accept-Encoding: identity, *;q=0")
	
	for h in extra_headers:
		if not "Accept-Encoding" in h:  # Don't duplicate
			headers.append(h)
	
	var body_str = "" if body.is_empty() else JSON.stringify(body)
	
	print("=== Request Debug ===")
	print("URL:", url)
	print("Headers:", headers)
	print("====================")
	
	var err = http_request.request(url, headers, method, body_str)
	
	if err != OK:
		push_error("HTTP Request failed: %s" % err)
		http_request.queue_free()
		if callback.is_valid():
			callback.call({}, 0)
		return
	
	http_request.request_completed.connect(
		func(result, response_code, response_headers, body_bytes):
			print("=== Response Debug ===")
			print("Result:", result)
			print("Code:", response_code)
			print("Response Headers:", response_headers)
			
			var text = body_bytes.get_string_from_utf8()
			var data = {}
			
			if result != HTTPRequest.RESULT_SUCCESS:
				push_error("Request failed with result: %s" % result)
				http_request.queue_free()
				if callback.is_valid():
					callback.call({}, 0)
				return
			
			if not text.is_empty():
				var parsed = JSON.parse_string(text)
				if parsed != null:
					data = parsed
			
			print("Data:", data)
			print("====================")
			
			if response_code >= 200 and response_code < 300:
				if data is Dictionary:
					if data.has("access_token"):
						access_token = data["access_token"]
					if data.has("refresh_token"):
						refresh_token = data["refresh_token"]
					if data.has("user"):
						current_user = data["user"]
			
			http_request.queue_free()
			if callback.is_valid():
				callback.call(data, response_code)
	)

# --- AUTH: SIGN IN ---
func sign_in(email: String, password: String, callback: Callable):
	var body: Dictionary = {
		"email": email,
		"password": password
	}
	_do_request("/auth/v1/token?grant_type=password", HTTPClient.METHOD_POST, body, callback)

# --- AUTH: SIGN UP ---
func sign_up(email: String, password: String, callback: Callable):
	var body: Dictionary = {
		"email": email,
		"password": password
	}
	_do_request("/auth/v1/signup", HTTPClient.METHOD_POST, body, callback)

# --- GET PROFILE ---
func get_profile(user_id: String, callback: Callable):
	var path = "/rest/v1/profiles?select=*&id=eq." + user_id
	var extra_headers = [
		"Accept: application/json",
		"Accept-Encoding: identity"
	]
	# Pass a flag to indicate this is a profile fetch
	var wrapped_callback = func(data, code):
		if code >= 200 and code < 300 and data is Array and not data.is_empty():
			current_user.merge(data[0], true)  # Safe to merge profile data
		if callback.is_valid():
			callback.call(data, code)
	
	_do_request(path, HTTPClient.METHOD_GET, {}, wrapped_callback, extra_headers)

# --- UPDATE PROFILE ---
func update_profile(profile_data: Dictionary, callback: Callable):
	if current_user.has("id"):
		var path = "/rest/v1/profiles?id=eq." + str(current_user["id"])
		
		var wrapped_callback = func(data, code):
			if code >= 200 and code < 300:
				# Merge the updated data into current_user
				current_user.merge(profile_data, true)
			if callback.is_valid():
				callback.call(data, code)
		
		_do_request(path, HTTPClient.METHOD_PATCH, profile_data, wrapped_callback)
	else:
		push_error("Supabase Error: No current user ID found.")

# --- GAME PROGRESS ---
func get_player_progress(user_id: String, callback: Callable):
	# Validate it's a UUID, not a number
	if user_id.is_empty() or user_id.is_valid_int():
		push_error("Invalid user_id passed to get_player_progress: " + user_id)
		if callback.is_valid():
			callback.call([], 400)
		return
	
	var path = "/rest/v1/player_progress?select=*&user_id=eq." + str(user_id)
	var extra_headers = [
		"Accept: application/json",
		"Accept-Encoding: identity"
	]
	_do_request(path, HTTPClient.METHOD_GET, {}, callback, extra_headers)

# --- HELPERS ---
func get_current_user() -> Dictionary:
	return current_user

func is_user_logged_in() -> bool:
	return not access_token.is_empty() and not current_user.is_empty()
