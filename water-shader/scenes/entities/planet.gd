extends MeshInstance3D

@export var spin_speed = 0.05

func _process(delta: float) -> void:
	rotation.z -= delta * spin_speed
