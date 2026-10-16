extends RigidBody2D

func _ready() -> void:
	# Hace que la mitad gire mientras cae en el aire
	angular_velocity = randf_range(-10.0, 10.0) #establece su velocidad de rotación.

func _physics_process(_delta: float) -> void:
	# Se elimina sola al caer fuera de la pantalla
	if global_position.y > 900:
		queue_free()
