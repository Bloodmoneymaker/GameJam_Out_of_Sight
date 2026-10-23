extends Area3D
class_name KillZone
## Put below holes and pits: a player falling in is sent back to the respawn point.

@export var respawn_point: Node3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerCharacter:
		GameManager.show_lose_screen()
