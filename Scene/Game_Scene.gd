extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SpawnManager.spawn_entity(SpawnManager.ENTITY.Player)
	if has_node("PlayerSpawn") and GameManager.container_entity.get_child_count() > 0:
		var player := GameManager.container_entity.get_child(GameManager.container_entity.get_child_count() - 1) as Node3D
		if is_instance_valid(player):
			player.global_transform = $PlayerSpawn.global_transform
