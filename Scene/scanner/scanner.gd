@tool
extends Node3D
@onready var anim_player:AnimationPlayer = $RecoilPivot/Node3D/AnimationPlayer
@onready var anim_tree:AnimationTree = $RecoilPivot/Node3D/AnimationTree
@onready var recoil_player:AnimationPlayer = $RecoilPivot/RecoilAnimationPlayer
@onready var scene_player:CharacterBody3D = $"../../.."

func _ready() -> void:
	anim_tree.active = true
	anim_player.play("Stand")

func _physics_process(_delta: float) -> void:
	if is_instance_valid(scene_player) and scene_player.velocity.z <= 0.1:
		anim_player.play("Stand")


func powerScan():
	$PowerScan.start()
	anim_player.play("Scan")


func play_power_recoil() -> void:
	recoil_player.play("PowerRecoil")


func _on_power_scan_timeout() -> void:
	anim_player.play("Stand")
