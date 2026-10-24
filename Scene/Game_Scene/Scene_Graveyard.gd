extends "res://Scene/Game_Scene.gd"

## Knoten, unter dem die AngelTeleportMarker liegen (leer = ganze Szene durchsuchen).
@export var teleport_markers_root: Node3D
## Zusätzliche Verzögerung, die auf jeden Marker-Delay addiert wird.
@export_range(0.0, 60.0, 0.1, "suffix:s") var teleport_delay_offset := 0.0
## Max. Abstand, den das Einrasten auf das Navmesh verschieben darf.
@export var max_navmesh_snap_distance := 3.0


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

	for marker in _get_teleport_markers():
		_schedule_teleport(marker)


func _get_spawned_player() -> Node3D:
	var container := GameManager.container_entity
	if not is_instance_valid(container):
		return null
	for index in range(container.get_child_count() - 1, -1, -1):
		var child := container.get_child(index) as Node3D
		if is_instance_valid(child) and child.is_in_group("player"):
			return child
	return null


func _get_teleport_markers() -> Array[AngelTeleportMarker]:
	var root: Node = teleport_markers_root if is_instance_valid(teleport_markers_root) else self
	var markers: Array[AngelTeleportMarker] = []
	for node in root.find_children("*", "Marker3D", true, false):
		if node is AngelTeleportMarker:
			markers.append(node)
	return markers


func _schedule_teleport(marker: AngelTeleportMarker) -> void:
	await get_tree().create_timer(marker.delay + teleport_delay_offset).timeout
	if is_instance_valid(marker) and is_instance_valid(marker.angel):
		_teleport_angel(marker)


func _teleport_angel(marker: AngelTeleportMarker) -> void:
	var target := marker.global_position
	if marker.snap_to_navmesh:
		var region := get_node_or_null("NavigationRegion3D") as NavigationRegion3D
		if is_instance_valid(region):
			var navigation_map := region.get_navigation_map()
			if navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
				var candidate := NavigationServer3D.map_get_closest_point(navigation_map, target)
				if candidate.distance_to(target) <= max_navmesh_snap_distance:
					target = candidate

	marker.angel.global_position = target
	if marker.apply_rotation:
		marker.angel.global_rotation.y = marker.global_rotation.y
