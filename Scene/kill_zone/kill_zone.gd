extends Area3D
class_name KillZone
## Put below holes and pits: a player falling in is sent back to the respawn point.

@export var respawn_point: Node3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerCharacter:
		body.global_position = respawn_point.global_position if respawn_point else Vector3(0, 1, 0)
		body.velocity = Vector3.ZERO
