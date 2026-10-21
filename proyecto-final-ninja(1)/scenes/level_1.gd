extends Node2D

signal partida_terminada(jugador: int, puntos: int)

var escena_fruta = preload("res://scenes/fruit.tscn")

@onready var spawneador = $Spawneador
@onready var timer_lanzamiento = $TimerLanzamiento
@onready var timer_juego = $TimerJuego
@onready var texto_puntos = $CanvasLayer/TextoPuntos
@onready var texto_tiempo = $CanvasLayer/TextoTiempo

@onready var fondo_versus = $fondo
@onready var fondo_solo = $fondosolo

var texto_puntos_j2: Label = null
var puntos_j1: int = 0
var puntos_j2: int = 0
var juego_terminado: bool = false
var es_versus: bool = false

func _ready() -> void:
	timer_lanzamiento.timeout.connect(_on_timer_lanzamiento_timeout)
	timer_juego.timeout.connect(_on_timer_juego_timeout)

	es_versus = (Global.modo == "versus" or Global.modo == "2")

	# 1. MOSTRAR / OCULTAR FONDO SEGÚN EL MODO
	if es_versus:
		if fondo_versus: fondo_versus.visible = true
		if fondo_solo: fondo_solo.visible = false
	else:
		if fondo_versus: fondo_versus.visible = false
		if fondo_solo: fondo_solo.visible = true

	# 2. CREAR CURSORES
	_crear_cursor(1)
	if es_versus:
		_crear_cursor(2)

	# 3. UBICAR LOS MARCADORES Y EL TIEMPO
	texto_puntos.visible = true
	texto_puntos.add_theme_font_size_override("font_size", 28)
	
	var ancho_pantalla = get_viewport_rect().size.x

	if es_versus:
		# Jugador 1 en la esquina superior izquierda
		texto_puntos.position = Vector2(40, 20)
		
		# Jugador 2 en la esquina superior derecha con espacio seguro
		texto_puntos_j2 = Label.new()
		texto_puntos_j2.add_theme_font_size_override("font_size", 28)
		texto_puntos_j2.position = Vector2(ancho_pantalla - 220, 20)
		$CanvasLayer.add_child(texto_puntos_j2)
		
		# Tiempo ubicado exactamente en el centro superior
		texto_tiempo.position = Vector2(ancho_pantalla / 2 - 60, 20)
	else:
		texto_puntos.position = Vector2(20, 20)
		texto_tiempo.position = Vector2(ancho_pantalla / 2 - 50, 20)

	_actualizar_texto_puntos()
	if es_versus:
		_crear_separador()
	
	texto_tiempo.visible = true
	texto_tiempo.add_theme_font_size_override("font_size", 28)

	timer_juego.wait_time = 45.0
	timer_juego.one_shot = true

	timer_lanzamiento.start(2.5)
	timer_juego.start()

func _process(_delta: float) -> void:
	# Actualizar el texto del temporizador para que muestre los segundos restantes
	if timer_juego and not juego_terminado:
		var segundos_restantes = ceil(timer_juego.time_left)
		texto_tiempo.text = "Tiempo: " + str(segundos_restantes) + "s"

	# Efecto de parpadeo en los últimos 5 segundos
	if timer_juego.time_left <= 5.0 and timer_juego.time_left > 0:
		var parpadeo = sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
		texto_tiempo.add_theme_color_override("font_color", Color(1.0, parpadeo, parpadeo))

func _on_timer_lanzamiento_timeout() -> void:
	if juego_terminado:
		return

	var ancho = get_viewport_rect().size.x
	var nueva_fruta = escena_fruta.instantiate()
	
	if es_versus:
		var lado = randi() % 2
		var propietario = lado + 1
		if lado == 0:
			nueva_fruta.position = Vector2(randf_range(ancho * 0.08, ancho * 0.42), spawneador.position.y)
		else:
			nueva_fruta.position = Vector2(randf_range(ancho * 0.58, ancho * 0.92), spawneador.position.y)
		nueva_fruta.get_node("RigidBody2D").jugador_destino = propietario
	else:
		nueva_fruta.position = Vector2(randf_range(ancho * 0.1, ancho * 0.9), spawneador.position.y)

	add_child(nueva_fruta)

func _crear_separador() -> void:
	var tamanio = get_viewport_rect().size
	var separador = Line2D.new()
	separador.width = 4.0
	separador.default_color = Color(0.2, 0.9, 1.0, 0.75)
	separador.add_point(Vector2(tamanio.x * 0.5, 0))
	separador.add_point(Vector2(tamanio.x * 0.5, tamanio.y))
	add_child(separador)

func sumar_punto(jugador: int = 1) -> void:
	if not juego_terminado:
		if jugador == 2:
			puntos_j2 += 1
		else:
			puntos_j1 += 1
		_actualizar_texto_puntos()

func restar_punto(jugador: int = 1) -> void:
	if not juego_terminado:
		if jugador == 2:
			puntos_j2 = max(0, puntos_j2 - 1)
		else:
			puntos_j1 = max(0, puntos_j1 - 1)
		_actualizar_texto_puntos()

func _actualizar_texto_puntos() -> void:
	if es_versus:
		texto_puntos.text = Global.nombres[1] + ": " + str(puntos_j1)
		if texto_puntos_j2:
			texto_puntos_j2.text = Global.nombres[2] + ": " + str(puntos_j2)
	else:
		texto_puntos.text = Global.nombres[1] + ": " + str(puntos_j1)

func _crear_cursor(id_jugador: int) -> void:
	var c = Area2D.new()
	c.set_script(preload("res://scripts/cursor.gd"))
	c.jugador = id_jugador
	c.modo = "webcam"
	c.restringir_zona = es_versus
	
	var ancho = get_viewport_rect().size.x
	var alto = get_viewport_rect().size.y
	if id_jugador == 1:
		c.position = Vector2(ancho * 0.25, alto / 2)
	else:
		c.position = Vector2(ancho * 0.75, alto / 2)

	var col = CollisionShape2D.new()
	var forma = CircleShape2D.new()
	forma.radius = 25
	col.shape = forma
	c.add_child(col)
	add_child(c)

func _on_timer_juego_timeout() -> void:
	juego_terminado = true
	timer_lanzamiento.stop()
	
	texto_puntos.visible = false
	if texto_puntos_j2:
		texto_puntos_j2.visible = false
		
	texto_tiempo.add_theme_font_size_override("font_size", 42)
	texto_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_tiempo.position = Vector2(100, 220)
	
	var max_puntos = max(puntos_j1, puntos_j2) if es_versus else puntos_j1
	
	if max_puntos >= 1:
		texto_tiempo.text = "¡NIVEL 1 SUPERADO!\nPuntos: " + str(max_puntos)
		if Global.nivel_desbloqueado < 2:
			Global.nivel_desbloqueado = 2
		await get_tree().create_timer(2.5).timeout
		get_tree().change_scene_to_file("res://scenes/select_level.tscn")
	else:
		texto_tiempo.text = "¡CASI! Necesitan 15 pts\nPuntos: " + str(max_puntos)
		await get_tree().create_timer(2.5).timeout
		get_tree().change_scene_to_file("res://scenes/level1.tscn")
		
		
		
