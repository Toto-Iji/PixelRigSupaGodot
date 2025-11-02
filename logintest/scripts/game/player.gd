# player.gd
extends CharacterBody2D

# --- Exported Properties ---
@export var speed: float = 250.0
@export var interact_distance: float = 50.0
@export var attack_range: float = 400.0
@export var fire_rate: float = 0.3  # 🆕 Time between shots (seconds)

# --- Node References ---
@onready var sprite: AnimatedSprite2D = $Sprite

# --- Signals ---
signal health_changed(new_health)

# --- State Variables ---
var can_move: bool = true
var max_health: int = 3
var health: int = max_health
var is_dead: bool = false
var stun_timer: Timer
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0
var knockback_duration: float = 0.3
var last_direction := Vector2.DOWN

# 🆕 SHOOTING COOLDOWN
var can_shoot: bool = true
var shoot_cooldown_timer: Timer

# --- Constants ---
const BULLET_SCENE = preload("res://scenes/game/bullet.tscn")

# --- Built-in Functions ---

func _ready():
	# Initialize stun timer
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	add_child(stun_timer)
	stun_timer.timeout.connect(_on_stun_end)
	
	# 🆕 Initialize shoot cooldown timer
	shoot_cooldown_timer = Timer.new()
	shoot_cooldown_timer.one_shot = true
	add_child(shoot_cooldown_timer)
	shoot_cooldown_timer.timeout.connect(_on_shoot_cooldown_end)

func _physics_process(delta):
	# --- 1. Handle Knockback ---
	if knockback_time > 0:
		velocity = knockback_vector
		knockback_time -= delta
		move_and_slide()
		return
	
	# --- 2. Handle Stun ---
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle-front")
		return
	
	# --- 3. Handle Attack Input ---
	# 🆕 FIXED: Check both button press AND cooldown
	if Input.is_action_pressed("Attack") and can_shoot:  # Changed to is_action_pressed
		var target = _get_nearest_hostile_in_range()
		if target:
			_shoot(target)
			# 🆕 Start cooldown
			can_shoot = false
			shoot_cooldown_timer.start(fire_rate)
		else:
			print("❌ No hostile in range")
	
	if Input.is_action_just_pressed("Interact"):
		_interact()
	
	# --- 4. Normal Movement Input ---
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	
	if input_vector != Vector2.ZERO:
		last_direction = input_vector.normalized()
		
	velocity = input_vector * speed
	move_and_slide()
	
	# --- 5. Animation Logic ---
	var is_moving = input_vector != Vector2.ZERO
	var animation_to_play = ""
	
	if is_moving:
		if abs(input_vector.x) > abs(input_vector.y):
			if input_vector.x < 0:
				sprite.flip_h = true 
				animation_to_play = "run-right"
			elif input_vector.x > 0:
				sprite.flip_h = false
				animation_to_play = "run-right"
		else:
			if input_vector.y < 0:
				sprite.flip_h = false
				animation_to_play = "back-run"
			elif input_vector.y > 0:
				sprite.flip_h = false
				animation_to_play = "front-run"
	else:
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x < 0:
				sprite.flip_h = true
				animation_to_play = "idle-right"
			else:
				sprite.flip_h = false
				animation_to_play = "idle-right"
		else:
			if last_direction.y < 0:
				sprite.flip_h = false
				animation_to_play = "idle-back"
			else:
				sprite.flip_h = false
				animation_to_play = "idle-front"

	if animation_to_play != "":
		sprite.play(animation_to_play)

# --- Health & Damage Functions ---

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	health = clamp(health, 0, max_health)
	print("Player HP:", health)

	emit_signal("health_changed", health)

	if health <= 0 and not is_dead:
		is_dead = true
		die()

func die() -> void:
	print("💀 Player is dead")
	
	clear_knockback() 
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	var world = get_tree().current_scene
	if world and world.has_method("show_death_popup"):
		world.show_death_popup()

# --- Knockback & Stun Functions ---

func clear_knockback():
	knockback_vector = Vector2.ZERO
	knockback_time = 0.0

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_vector = direction.normalized() * force
	knockback_time = knockback_duration

func stun(duration: float) -> void:
	can_move = false
	stun_timer.start(duration)

func _on_stun_end() -> void:
	can_move = true

# 🆕 Shoot cooldown handler
func _on_shoot_cooldown_end() -> void:
	can_shoot = true

# --- Respawn & Reset Functions ---

func respawn_at(spawn_position: Vector2) -> void:
	var original_collision_layer = collision_layer
	var original_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	
	velocity = Vector2.ZERO
	clear_knockback()
	can_move = true
	health = max_health
	is_dead = false
	can_shoot = true  # 🆕 Reset shooting ability
	set_physics_process(true)
	
	global_position = spawn_position
	
	await get_tree().create_timer(0.1).timeout
	
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
	
	_reset_all_hostiles()

func _reset_all_hostiles() -> void:
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	for hostile in hostiles:
		if hostile and hostile.has_method("reset_state"):
			hostile.reset_state()

# --- Combat Functions ---

func _shoot(target: Node2D):
	velocity = Vector2.ZERO
	
	var bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	var dir = (target.global_position - global_position).normalized()
	
	bullet.global_position = global_position + dir * 24 
	bullet.rotation = dir.angle()
	bullet.shooter = self
	bullet.direction = dir
	
	print("🔫 Fired! Cooldown: %.2fs" % fire_rate)

func _get_nearest_hostile_in_range() -> Node2D:
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	var closest: Node2D = null
	var closest_dist := INF
	
	for h in hostiles:
		if h:
			var d = global_position.distance_to(h.global_position)
			if d < closest_dist and d <= attack_range:
				closest_dist = d
				closest = h
	return closest

# --- Interaction Function ---

func _interact():
	print("Interact key pressed!")
	
	var space_state = get_world_2d().direct_space_state
	var circle = CircleShape2D.new()
	circle.radius = interact_distance
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = global_transform
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var results = space_state.intersect_shape(query)
	
	print("Found ", results.size(), " objects nearby")
	
	var closest_body: Node = null
	var closest_distance = INF
	
	for result in results:
		var body = result.collider
		print("  - Found:", body.name, " | Has interact:", body.has_method("interact"))
		if body == self:
			continue
		if body.has_method("interact"):
			var distance = global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_body = body
	
	if closest_body:
		print("Interacting with:", closest_body.name)
		closest_body.interact()
	else:
		print("No interactable objects found")
