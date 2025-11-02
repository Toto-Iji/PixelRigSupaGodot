# supabase.gd
extends Node

# ---! CONFIGURATION !---
const SUPABASE_URL = "https://zrilkyxisplfanzloauu.supabase.co"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpyaWxreXhpc3BsZmFuemxvYXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4MjE3NTUsImV4cCI6MjA3MzM5Nzc1NX0.7EoKEemphqyTZ7YAbXJF3EKqrxahXWpz8yLu_k-iSiY"
# -----------------------

# --- VARIABLES ---
var access_token: String = ""
var refresh_token: String = ""
var current_user: Dictionary = {}

func _ready():
	load_session()  # Auto-login if session exists

# --- DEFAULT HEADERS ---
func _get_default_headers() -> Array[String]:
	var headers: Array[String] = [
		"apikey: " + SUPABASE_KEY,
		"Content-Type: application/json",
		"Accept-Encoding: identity"
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
	
	var url = SUPABASE_URL + path
	
	# Keep your original header handling - it's needed for web!
	var headers = _get_default_headers()
	# Remove any existing Accept-Encoding
	headers = headers.filter(func(h): return not "Accept-Encoding" in h)
	# Add identity ONLY
	headers.append("Accept-Encoding: identity, *;q=0")
	
	for h in extra_headers:
		if not "Accept-Encoding" in h:
			headers.append(h)
	
	var body_str = "" if body.is_empty() else JSON.stringify(body)
	
	var err = http_request.request(url, headers, method, body_str)
	
	if err != OK:
		push_error("Supabase: HTTP Request failed: %s" % err)
		http_request.queue_free()
		if callback.is_valid():
			callback.call({}, 0)
		return
	
	http_request.request_completed.connect(
		func(result, response_code, _response_headers, body_bytes):
			var data = {}
			
			if result != HTTPRequest.RESULT_SUCCESS:
				push_error("Supabase: Request failed with result: %s" % result)
				http_request.queue_free()
				if callback.is_valid():
					callback.call({}, 0)
				return
			
			var text = body_bytes.get_string_from_utf8()
			if not text.is_empty():
				var parsed = JSON.parse_string(text)
				if parsed != null:
					data = parsed
			
			# Update tokens and user if present
			if response_code >= 200 and response_code < 300:
				if data is Dictionary:
					if data.has("access_token"):
						access_token = data["access_token"]
						save_session()  # Auto-save on successful auth
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

# --- AUTH: SIGN OUT ---
func sign_out():
	access_token = ""
	refresh_token = ""
	current_user = {}
	clear_session()

# --- GET PROFILE ---
func get_profile(user_id: String, callback: Callable):
	var path = "/rest/v1/profiles?select=*&id=eq." + user_id
	var extra_headers = [
		"Accept: application/json",
		"Accept-Encoding: identity"
	]
	var wrapped_callback = func(data, code):
		if code >= 200 and code < 300 and data is Array and not data.is_empty():
			current_user.merge(data[0], true)
			save_session()  # Save updated profile
		if callback.is_valid():
			callback.call(data, code)
	
	_do_request(path, HTTPClient.METHOD_GET, {}, wrapped_callback, extra_headers)

# --- UPDATE PROFILE ---
func update_profile(profile_data: Dictionary, callback: Callable):
	if current_user.has("id"):
		var path = "/rest/v1/profiles?id=eq." + str(current_user["id"])
		
		var wrapped_callback = func(data, code):
			if code >= 200 and code < 300:
				current_user.merge(profile_data, true)
				save_session()  # Save updated profile
			if callback.is_valid():
				callback.call(data, code)
		
		_do_request(path, HTTPClient.METHOD_PATCH, profile_data, wrapped_callback)
	else:
		push_error("Supabase: No current user ID found.")

# --- GAME PROGRESS ---
func get_player_levels(callback: Callable):
	var path = "/rest/v1/player_levels?select=*"
	var extra_headers = [
		"Accept: application/json",
		"Accept-Encoding: identity, *;q=0"
	]
	_do_request(path, HTTPClient.METHOD_GET, {}, callback, extra_headers)

func unlock_next_level(current_level_id: String, callback: Callable):
	var path = "/rest/v1/rpc/unlock_next_level"
	var body = {
		"current_level_id": current_level_id
	}
	_do_request(path, HTTPClient.METHOD_POST, body, callback)

# --- COMPONENTS ---
func get_player_components(callback: Callable):
	var path = "/rest/v1/player_components?select=*"
	var extra_headers = [
		"Accept: application/json",
		"Accept-Encoding: identity, *;q=0"
	]
	_do_request(path, HTTPClient.METHOD_GET, {}, callback, extra_headers)

func collect_component(component_id: String, callback: Callable):
	var path = "/rest/v1/rpc/collect_component"
	var body = {
		"p_component_id": component_id
	}
	_do_request(path, HTTPClient.METHOD_POST, body, callback)

func install_component(component_id: String, callback: Callable):
	var path = "/rest/v1/rpc/install_component"
	var body = {
		"p_component_id": component_id
	}
	_do_request(path, HTTPClient.METHOD_POST, body, callback)

# --- SESSION PERSISTENCE ---
func save_session():
	var file = FileAccess.open("user://session.dat", FileAccess.WRITE)
	if file:
		var session = {
			"access_token": access_token,
			"refresh_token": refresh_token,
			"user": current_user
		}
		file.store_string(JSON.stringify(session))
		file.close()

func load_session() -> bool:
	if not FileAccess.file_exists("user://session.dat"):
		return false
	
	var file = FileAccess.open("user://session.dat", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		
		if json and json is Dictionary:
			access_token = json.get("access_token", "")
			refresh_token = json.get("refresh_token", "")
			current_user = json.get("user", {})
			return not access_token.is_empty()
	return false

func clear_session():
	if FileAccess.file_exists("user://session.dat"):
		DirAccess.remove_absolute("user://session.dat")

# --- QUIZ FUNCTIONS ---

func get_questions_for_level(level_id: String, callback: Callable):
	var path = "/rest/v1/questions?select=*&level_id=eq." + level_id + "&order=created_at.asc"
	var extra_headers = [
		"Accept: application/json",
		"Accept-Encoding: identity, *;q=0"
	]
	_do_request(path, HTTPClient.METHOD_GET, {}, callback, extra_headers)


func save_quiz_score(level_id: String, score: int, total_questions: int, callback: Callable):
	if current_user.is_empty() or not current_user.has("id"):
		push_error("Cannot save quiz score: No user logged in")
		if callback.is_valid():
			callback.call({}, 401)
		return

	var score_data = {
		"user_id": str(current_user.id),
		"level_id": level_id,
		"score": score,
		"total_questions": total_questions
	}
	
	# 🆕 ADD DEBUG
	print("💾 Saving to database:")
	print("  Level ID: %s" % level_id)
	print("  Score: %d" % score)
	print("  Total Questions: %d" % total_questions)
	print("  JSON: %s" % JSON.stringify(score_data))

	_do_request("/rest/v1/quiz_scores", HTTPClient.METHOD_POST, score_data, callback)


func get_user_quiz_scores(callback: Callable):
	if current_user.is_empty() or not current_user.has("id"):
		push_error("Cannot fetch quiz scores: No user logged in")
		if callback.is_valid():
			callback.call([], 401)
		return

	var path = "/rest/v1/quiz_scores?select=*&user_id=eq." + str(current_user.id) + "&order=completed_at.desc"
	var extra_headers = [
		"Accept: application/json",
		"Accept-Encoding: identity, *;q=0"
	]
	_do_request(path, HTTPClient.METHOD_GET, {}, callback, extra_headers)

# --- HELPERS ---
func get_current_user() -> Dictionary:
	return current_user

func is_user_logged_in() -> bool:
	return not access_token.is_empty() and not current_user.is_empty()
