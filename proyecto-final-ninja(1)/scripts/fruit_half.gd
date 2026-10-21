extends RigidBody2D

var jugador_destino: int = 0

# También impide que las piezas cortadas crucen al otro campo.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if jugador_destino == 0:
		return
	var ancho = get_viewport_rect().size.x
	var centro = ancho * 0.5
	var minimo = 8.0 if jugador_destino == 1 else centro + 8.0
	var maximo = centro - 8.0 if jugador_destino == 1 else ancho - 8.0
	var tr = state.transform
	var nueva_x = clampf(tr.origin.x, minimo, maximo)
	if nueva_x != tr.origin.x:
		tr.origin.x = nueva_x
		state.transform = tr
		var vel = state.linear_velocity
		vel.x = 0.0
		state.linear_velocity = vel

func _ready() -> void:
	# Hace que la mitad gire mientras cae en el aire
	angular_velocity = randf_range(-10.0, 10.0) #establece su velocidad de rotación.

func _physics_process(_delta: float) -> void:
	# Se elimina sola al caer fuera de la pantalla
	if global_position.y > 900:
		queue_free()
