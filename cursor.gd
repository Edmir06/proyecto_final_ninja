extends Area2D

var jugador: int = 1
var modo: String = "webcam"
var velocidad: float = 700.0

# EFECTO DE ESTELA (TRAIL)
var estela: Line2D
var puntos_estela: Array[Vector2] = []
var max_puntos: int = 10

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_contacto)
	
	# Inicializar la estela visual según el jugador
	estela = Line2D.new()
	estela.width = 10.0
	var color_base = Color.RED if jugador == 1 else Color.DEEP_SKY_BLUE
	estela.default_color = color_base
	
	# Gradiente para desvanecer la cola del movimiento
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(color_base.r, color_base.g, color_base.b, 0.0))
	gradiente.set_color(1, color_base)
	estela.gradient = gradiente
	
	get_parent().call_deferred("add_child", estela)

func _process(delta: float) -> void:
	match modo:
		"mouse":
			position = get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		"teclado":
			var dir = Input.get_vector("p2_izq", "p2_der", "p2_arriba", "p2_abajo")
			position += dir * velocidad * delta
		"ia":
			_mover_ia(delta)
		"webcam":
			_mover_webcam()
			
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)
	
	# Actualizar los puntos de la estela con la posición global
	puntos_estela.append(global_position)
	if puntos_estela.size() > max_puntos:
		puntos_estela.pop_front()
		
	if estela:
		estela.clear_points()
		for p in puntos_estela:
			estela.add_point(p)

func _mover_webcam() -> void:
	if jugador == 1:
		if RedWebcam.j1_detectado:
			global_position = RedWebcam.pos_j1
	elif jugador == 2:
		if RedWebcam.j2_detectado:
			global_position = RedWebcam.pos_j2

func _physics_process(_delta: float) -> void:
	var cuerpos = get_overlapping_bodies()
	for cuerpo in cuerpos:
		_on_contacto(cuerpo)

func _mover_ia(delta: float) -> void:
	var objetivo: Node2D = null
	var mejor := INF
	for fruta in get_tree().get_nodes_in_group("frutas"):
		if fruta.get_parent() != get_parent():
			continue
		var d = global_position.distance_to(fruta.global_position)
		if d < mejor:
			mejor = d
			objetivo = fruta
	if objetivo:
		global_position = global_position.move_toward(objetivo.global_position, velocidad * 0.6 * delta)

func _on_contacto(otro: Node) -> void:
	var objetivo = otro
	if not objetivo.has_method("cortar") and objetivo.get_parent() != null:
		objetivo = objetivo.get_parent()
		
	if objetivo.has_method("cortar"):
		objetivo.cortar(jugador)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20, Color.RED if jugador == 1 else Color.DEEP_SKY_BLUE)
