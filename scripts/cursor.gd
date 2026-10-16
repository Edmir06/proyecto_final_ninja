extends Area2D

var jugador: int = 1
var modo: String = "webcam"
var velocidad: float = 700.0

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_contacto)

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
