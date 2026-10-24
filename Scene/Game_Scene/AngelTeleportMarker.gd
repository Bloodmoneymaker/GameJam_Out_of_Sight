class_name AngelTeleportMarker
extends Marker3D

## Engel, der zu diesem Marker teleportiert wird.
@export var angel: Node3D
## Sekunden nach Szenenstart, nach denen teleportiert wird.
@export_range(0.0, 600.0, 0.1, "suffix:s") var delay := 2.0
## Position auf das nächste Navmesh-Polygon einrasten.
@export var snap_to_navmesh := true
## Engel nach dem Teleport in Marker-Richtung (-Z) drehen.
@export var apply_rotation := false
