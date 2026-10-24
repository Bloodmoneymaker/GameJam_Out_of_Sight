extends "res://Scene/Game_Scene.gd"

const ANGEL_SCRIPT := preload("res://Scene/Enemy/angel_enemy.gd")
const ANGEL_TELEPORT_DELAY := 2.0


func _ready() -> void:
	super._ready()
	await get_tree().process_frame

	var player := _get_spawned_player()
	if not is_instance_valid(player):
		return
	var head := player.get_node_or_null("Head") as Node3D
	var charger := player.get_node_or_null("EchoCharger")
	if is_instance_valid(head) and is_instance_valid(charger) and charger.has_method("try_scan"):
		charger.call("try_scan", head.global_position)
	else:
		Echo.player_scan_echo(player.global_position + Vector3.UP)

	await get_tree().create_timer(ANGEL_TELEPORT_DELAY).timeout
	if is_instance_valid(player):
		_teleport_angels(player)


func _get_spawned_player() -> Node3D:
	var container := GameManager.container_entity
	if not is_instance_valid(container):
		return null
	for index in range(container.get_child_count() - 1, -1, -1):
		var child := container.get_child(index) as Node3D
		if is_instance_valid(child) and child.is_in_group("player"):
			return child
	return null


func _teleport_angels(player: Node3D) -> void:
	var region := get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if not is_instance_valid(region):
		return
	var navigation_map := region.get_navigation_map()
	if not navigation_map.is_valid() or NavigationServer3D.map_get_iteration_id(navigation_map) <= 0:
		return

	var angels: Array[Enemy] = []
	for node in find_children("*", "CharacterBody3D", true, false):
		if node.get_script() == ANGEL_SCRIPT:
			angels.append(node as Enemy)
	angels.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.global_position.x < b.global_position.x)

	for index in range(angels.size()):
		var angel := angels[index]
		var edge_positions: Array[Vector3] = [
			Vector3(-4.0, player.global_position.y, -40.0) if index % 2 == 0 else Vector3(39.0, player.global_position.y, -40.0),
			Vector3(39.0, player.global_position.y, 1.0) if index % 2 == 0 else Vector3(-4.0, player.global_position.y, 1.0),
			Vector3(1.0, player.global_position.y, 3.0) if index % 2 == 0 else Vector3(37.0, player.global_position.y, 3.0),
			Vector3(20.0, player.global_position.y, -41.0),
		]
		for desired in edge_positions:
			var candidate := NavigationServer3D.map_get_closest_point(navigation_map, desired)
			if candidate.distance_to(desired) > 3.0 or candidate.distance_to(player.global_position) < 12.0 or candidate.distance_to(angel.global_position) < 8.0:
				continue
			angel.global_position = candidate
			break
