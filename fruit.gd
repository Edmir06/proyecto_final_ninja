extends RigidBody2D

var datos_frutas = [
	{
		"entera": preload("res://assets/battery.png"),
		"izq": preload("res://assets/battery left.png"),
		"der": preload("res://assets/battery right.png"),
		"es_basura": true,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/cable.png"),
		"izq": preload("res://assets/cable left.png"),
		"der": preload("res://assets/cable right.png"),
		"es_basura": true,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/command.png"),
		"izq": preload("res://assets/command left.png"),
		"der": preload("res://assets/command right.png"),
		"es_basura": false,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/laptop.png"),
		"izq": preload("res://assets/laptop left.png"),
		"der": preload("res://assets/laptop right.png"),
		"es_basura": false,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/mouse.png"),
		"izq": preload("res://assets/mouse left.png"),
		"der": preload("res://assets/mouse right.png"),
		"es_basura": false,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/phone.png"),
		"izq": preload("res://assets/phone left.png"),
		"der": preload("res://assets/phone right.png"),
		"es_basura": false,
		"escala": Vector2(0.4, 0.4)
	}
]

var fruta_actual: Dictionary
var escena_mitad = preload("res://scenes/fruit_half.tscn")

@export var fuerza_impulso: Vector2 = Vector2(150, -750)

var frenado_aplicado: bool = false
var ya_cortada: bool = false

func _ready() -> void:
	add_to_group("frutas")

	var lista_disponible = []
	var escena_actual = get_tree().current_scene
	
	var ruta = ""
	var nombre_nodo = ""
	if escena_actual:
		ruta = escena_actual.scene_file_path.to_lower()
		nombre_nodo = escena_actual.name.to_lower()

	# Lógica de filtrado adaptada a "level1" / "nivel_1"
	if "level1" in ruta or "nivel_1" in ruta or "nivel1" in ruta or "level1" in nombre_nodo or "nivel_1" in nombre_nodo:
		# NIVEL 1: Sin basura (ni baterías ni cables)
		for f in datos_frutas:
			if not f.get("es_basura", false):
				lista_disponible.append(f)
				
	elif "level2" in ruta or "nivel_2" in ruta or "nivel2" in ruta or "level2" in nombre_nodo or "nivel_2" in nombre_nodo:
		# NIVEL 2: Baterías permitidas, se filtran los cables
		for f in datos_frutas:
			var es_cable = "cable" in f["entera"].resource_path.to_lower()
			if not es_cable:
				lista_disponible.append(f)
	else:
		# NIVEL 3 / MAIN: Modo completo con toda la basura
		lista_disponible = datos_frutas

	fruta_actual = lista_disponible.pick_random()

	$Sprite2D.texture = fruta_actual["entera"]

	var esc = fruta_actual.get("escala", Vector2(1, 1))
	$Sprite2D.scale = esc
	$CollisionShape2D.scale = esc

	apply_central_impulse(
		Vector2(randf_range(-100, 100), fuerza_impulso.y)
	)

func _physics_process(_delta: float) -> void:
	if not frenado_aplicado and linear_velocity.y >= -50 and linear_velocity.y <= 50:
		frenado_aplicado = true
		gravity_scale = 0.2
		await get_tree().create_timer(0.5).timeout
		gravity_scale = 1.0

	if position.y > 800:
		queue_free()

func cortar(jugador: int) -> void:
	if ya_cortada:
		return

	ya_cortada = true

	var nodo_actual = get_parent()

	while nodo_actual != null and not nodo_actual.has_method("sumar_punto"):
		nodo_actual = nodo_actual.get_parent()

	if nodo_actual != null:
		if fruta_actual.get("es_basura", false):
			if nodo_actual.has_method("restar_punto"):
				nodo_actual.restar_punto(jugador)
		else:
			nodo_actual.sumar_punto(jugador)

	# --- SOLO LAS CHISPITAS ELÉCTRICAS AL CORTAR ---
	_crear_chispas_circuito(global_position, jugador, fruta_actual.get("es_basura", false))
	# -----------------------------------------------

	var esc = fruta_actual.get("escala", Vector2(1, 1))

	crear_mitad(
		fruta_actual["izq"],
		Vector2(-150, -200),
		-15,
		esc
	)

	crear_mitad(
		fruta_actual["der"],
		Vector2(150, -200),
		15,
		esc
	)

	queue_free()

func crear_mitad(
	textura: Texture2D,
	impulso: Vector2,
	offset_x: float,
	esc: Vector2
) -> void:
	var mitad = escena_mitad.instantiate()

	mitad.position = position + Vector2(offset_x, 0)

	var sprite_mitad = mitad.get_node("Sprite2D")
	sprite_mitad.texture = textura
	sprite_mitad.scale = esc

	get_parent().add_child(mitad)
	mitad.apply_central_impulse(impulso)

# --- FUNCIÓN DE CHISPAS ELÉCTRICAS ---
func _crear_chispas_circuito(pos: Vector2, id_jugador: int, es_basura: bool) -> void:
	var particulas = CPUParticles2D.new()
	particulas.global_position = pos
	particulas.emitting = true
	particulas.one_shot = true
	particulas.explosiveness = 0.95
	particulas.amount = 18
	particulas.lifetime = 0.4
	particulas.spread = 180.0
	particulas.gravity = Vector2(0, 350)
	particulas.initial_velocity_min = 140.0
	particulas.initial_velocity_max = 260.0
	particulas.scale_amount_min = 3.0
	particulas.scale_amount_max = 7.0
	
	particulas.color = Color(1.0, 0.4, 0.2) if es_basura else (Color(0.2, 1.0, 0.5) if id_jugador == 1 else Color(0.1, 0.7, 1.0))
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(particulas)
	
	await get_tree().create_timer(0.45).timeout
	particulas.queue_free()
