extends Node2D

func _ready():
	var tilemap = $TileMap  # Adjust to your TileMap node name
	
	# Get the used rectangle (actual level bounds)
	var used_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	
	# Calculate world size in pixels
	var world_size = used_rect.size * tile_size
	
	print("Used Rect: ", used_rect)
	print("Tile Size: ", tile_size)
	print("World Size: ", world_size)
