extends Sprite2D

@export var player_path: NodePath
@export var map_size := Vector2(256, 256)  # Your minimap background image size
@export var world_size := Vector2(1760, 400)  # Your actual level size

var player: Node2D

func _ready():
	player = get_node(player_path)

func _process(_delta):
	if player:
		# Convert world position to minimap position
		var normalized_pos = player.global_position / world_size
		position = normalized_pos * map_size
