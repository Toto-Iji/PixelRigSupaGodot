extends Node

# ---! CONFIGURATION !---
const SUPABASE_URL = "https://zrilkyxisplfanzloauu.supabase.co"  # Replace with your actual URL
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpyaWxreXhpc3BsZmFuemxvYXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4MjE3NTUsImV4cCI6MjA3MzM5Nzc1NX0.7EoKEemphqyTZ7YAbXJF3EKqrxahXWpz8yLu_k-iSiY" # Replace with your actual anon key
# -----------------------

# --- Private State ---
var _access_token: String = ""
var _refresh_token: String = ""
var _current_user: Dictionary = {}
var _http: HTTPRequest

# --- Public API ---

# --- Initialization ---
func _ready():
	_http = HTTPRequest.new()
	add_child(_http)

# --- Auth: Sign Up ---
func sign_up(email: String, password: String, username: String, callback: Callable):
	var body = {
		"email": email,
		"password": password,
		"options": {
			"data": {
				"username": username
			}
		}
	}
	_do_request("/auth/v1/signup", body, callback)

# --- Auth: Login ---
func sign_in(email: String, password: String, callback: Callable):
	var body = {
		"email": email,
		"password": password
	}
	_do_request("/auth/v1/token?grant_type=password", body, callback)
	
# --- User State Getters ---
func get_current_user() -> Dictionary:
	return _current_user

func is_user_logged_in() -> bool:
	return not _access_token.is_empty() and not _current_user.is_empty()

# --- Private Implementation ---

func _get_auth_headers() -> Array[String]:
	var default_headers: Array[String] = [
		"apikey: " + SUPABASE_KEY,
		"Content-Type: application/json"
	]
	if not _access_token.is_empty():
		default_headers.append("Authorization: Bearer " + _access_token)
	return default_headers

func _do_request(path: String, body: Dictionary, callback: Callable, method: int = HTTPClient.METHOD_POST, headers: Array = []):
	var request_headers = headers if not headers.is_empty() else _get_auth_headers()
	var url = SUPABASE_URL + path
	var json_body = JSON.stringify(body) if not body.is_empty() else ""

	print("Supabase Request: Sending request to -> ", path)
	
	# Using .bind() is safer than a temporary variable. It passes the callback
	# as an argument to the connected function. CONNECT_ONE_SHOT ensures it
	# disconnects automatically after firing.
	var err = _http.request_completed.connect(_on_request_completed.bind(callback), CONNECT_ONE_SHOT)
	if err != OK:
		push_error("Supabase Error: Failed to connect request_completed signal.")
		return
		
	var request_err = _http.request(url, request_headers, method, json_body)
	if request_err != OK:
		push_error("Supabase Error: HTTP request failed with error code %s" % request_err)
		# Ensure the one-shot connection is removed if the request itself fails
		if _http.is_connected("request_completed", _on_request_completed):
			_http.request_completed.disconnect(_on_request_completed)

func _on_request_completed(_result, response_code, _headers, body, original_callback):
	var text = body.get_string_from_utf8()
	var data = {}
	if not text.is_empty():
		var parsed_result = JSON.parse_string(text)
		if parsed_result != null:
			data = parsed_result
		else:
			print("Supabase Warning: Failed to parse JSON response. Body: ", text)
	
	print("Supabase Response: Code ", response_code)

	# --- Internal State Management ---
	# Only modify internal state on a successful request.
	if response_code >= 200 and response_code < 300:
		# Handle session data on successful auth
		if data.has("access_token"):
			_access_token = data["access_token"]
		if data.has("refresh_token"):
			_refresh_token = data["refresh_token"]
		if data.has("user"):
			_current_user = data["user"]
		
		# --- Profile Data Merging ---
		
		# Case 1: The response is for a GET profile request (returns an array)
		if data is Array and not data.is_empty():
			var profile_data = data[0]
			_current_user.merge(profile_data, true)
			print("Supabase Status: Profile data loaded and merged into current user.")
		
		# Case 2: The response is for a PATCH profile update.
		# This logic is now correctly placed *inside* the success block.
		var update_data: Dictionary
		if data is Array and not data.is_empty():
			# PostgREST often returns an array with the updated object
			update_data = data[0]
		elif data is Dictionary:
			# It might also return just the object
			update_data = data
		
		# If we have update data and it contains our key, merge it into the local user object.
		if not update_data.is_empty() and update_data.has("favorite_quote"):
			_current_user.merge(update_data, true)
			print("Supabase Status: Local user profile updated after saving.")

	# --- Callback Execution ---
	# This should always run, whether the request succeeded or failed,
	# so the calling script knows the operation is complete.
	if original_callback is Callable and original_callback.is_valid():
		original_callback.call(data, response_code)

# --- Profiles: Update Current User Profile ---
func update_profile(profile_data: Dictionary, callback: Callable):
	if not is_user_logged_in():
		push_error("Supabase Error: Cannot update profile. No user is logged in.")
		return
		
	var user_id = _current_user.get("id", "")
	var path = "/rest/v1/profiles?id=eq." + user_id
	var headers = _get_auth_headers()
	_do_request(path, profile_data, callback, HTTPClient.METHOD_PATCH, headers)

# --- Profiles: Get Current User Profile ---
func get_profile(callback: Callable):
	if not is_user_logged_in():
		push_error("Supabase Error: Cannot get profile. No user is logged in.")
		return
		
	var user_id = _current_user.get("id", "")
	var path = "/rest/v1/profiles?select=*&id=eq." + user_id
	var headers = _get_auth_headers()
	_do_request(path, {}, callback, HTTPClient.METHOD_GET, headers)
	
# --- Profiles: Get Email from Username ---
func get_email_from_username(username: String, callback: Callable):
	print("Supabase Request: Looking up email for username: ", username)
	# This query selects only the email column where the username matches exactly.
	var path = "/rest/v1/profiles?select=email&username=eq." + username
	# This is a public lookup, so we don't need auth headers.
	var headers: Array[String] = [
		"apikey: " + SUPABASE_KEY,
		"Content-Type: application/json"
	]
	_do_request(path, {}, callback, HTTPClient.METHOD_GET, headers)
	
# In supabase.gd
func get_player_progress(callback: Callable):
	if not is_user_logged_in(): return
	var user_id = _current_user.get("id")
	# This path gets all progress entries for the currently logged-in user.
	var path = "/rest/v1/player_progress?select=*&user_id=eq." + user_id
	var headers = _get_auth_headers()
	_do_request(path, {}, callback, HTTPClient.METHOD_GET, headers)
