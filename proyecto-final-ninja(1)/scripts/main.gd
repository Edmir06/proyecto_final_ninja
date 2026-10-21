extends Node2D

signal partida_terminada(jugador: int, puntos: int)

var escena_fruta = preload("res://scenes/fruit.tscn")

@onready var spawneador = $Spawneador
@onready var timer_lanzamiento = $TimerLanzamiento
@onready var timer_juego = $TimerJuego
@onready var texto_puntos = $CanvasLayer/TextoPuntos
@onready var texto_tiempo = $CanvasLayer/TextoTiempo

# Los asigna versus.gd / control.gd antes de añadir la escena
var jugador_id: int = 1
var es_ia: bool = false

var puntos: int = 0
var puntos_j2: int = 0
var texto_puntos_j2: Label = null
var es_versus_compartido: bool = false
var juego_terminado: bool = false

func _ready() -> void:
	timer_lanzamiento.timeout.connect(_on_timer_lanzamiento_timeout)
	timer_juego.timeout.connect(_on_timer_juego_timeout)
	# Nivel 3 compartido: dos jugadores en la misma escena.
	# Las antiguas partidas con SubViewports conservan un jugador por escena.
	es_versus_compartido = (Global.modo == "versus" or Global.modo == "2") and not (get_viewport() is SubViewport)
	_crear_cursor(jugador_id)
	if es_versus_compartido:
		_crear_cursor(2)
		_crear_separador()
		texto_puntos_j2 = Label.new()
		texto_puntos_j2.add_theme_font_size_override("font_size", 28)
		texto_puntos_j2.position = Vector2(get_viewport_rect().size.x - 220, 20)
		$CanvasLayer.add_child(texto_puntos_j2)

	# --- Marcador de Puntos ---
	texto_puntos.visible = true
	texto_puntos.position = Vector2(20, 20)
	texto_puntos.add_theme_font_size_override("font_size", 28)
	texto_puntos.text = Global.nombres[jugador_id] + ": 0"
	if texto_puntos_j2:
		texto_puntos_j2.text = Global.nombres[2] + ": 0"
	
	# --- Marcador de Tiempo ---
	texto_tiempo.visible = true
	texto_tiempo.position = Vector2(180, 20)
	texto_tiempo.add_theme_font_size_override("font_size", 28)

	# Iniciar el temporizador con una leve pausa inicial para evitar bugs de físicas
	timer_lanzamiento.start(2)
	
	
func _process(_delta: float) -> void:
	if not juego_terminado:
		texto_tiempo.text = "Time: " + str(int(timer_juego.time_left))

func _on_timer_lanzamiento_timeout() -> void:
	if juego_terminado:
		return

	var ancho = get_viewport_rect().size.x
	var nueva_fruta = escena_fruta.instantiate()
	if es_versus_compartido:
		var lado = randi() % 2
		nueva_fruta.get_node("RigidBody2D").jugador_destino = lado + 1
		if lado == 0:
			nueva_fruta.position = Vector2(randf_range(ancho * 0.08, ancho * 0.42), spawneador.position.y)
		else:
			nueva_fruta.position = Vector2(randf_range(ancho * 0.58, ancho * 0.92), spawneador.position.y)
	else:
		nueva_fruta.position = Vector2(randf_range(ancho * 0.1, ancho * 0.9), spawneador.position.y)
	add_child(nueva_fruta)

func sumar_punto(jugador: int = 0) -> void:
	if juego_terminado:
		return
	if es_versus_compartido and jugador == 2:
		puntos_j2 += 1
		texto_puntos_j2.text = Global.nombres[2] + ": " + str(puntos_j2)
	else:
		puntos += 1
		texto_puntos.text = Global.nombres[jugador_id] + ": " + str(puntos)

func restar_punto(jugador: int = 0) -> void:
	if juego_terminado:
		return
	if es_versus_compartido and jugador == 2:
		puntos_j2 = max(0, puntos_j2 - 1)
		texto_puntos_j2.text = Global.nombres[2] + ": " + str(puntos_j2)
	else:
		puntos = max(0, puntos - 1)
		texto_puntos.text = Global.nombres[jugador_id] + ": " + str(puntos)

func _on_timer_juego_timeout() -> void:
	juego_terminado = true
	timer_lanzamiento.stop()
	
	texto_puntos.visible = false
	if texto_puntos_j2:
		texto_puntos_j2.visible = false
	
	texto_tiempo.add_theme_font_size_override("font_size", 42)
	if es_versus_compartido:
		var ganador = Global.nombres[1] if puntos > puntos_j2 else Global.nombres[2]
		texto_tiempo.text = "¡EMPATE!" if puntos == puntos_j2 else "¡GANA " + ganador + "!"
		texto_tiempo.text += "\n" + str(puntos) + " - " + str(puntos_j2)
	else:
		texto_tiempo.text = "¡FINISH!\nPuntos: " + str(puntos)
	texto_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_tiempo.position = Vector2(100, 220)
	
	partida_terminada.emit(jugador_id, puntos)

func _crear_separador() -> void:
	var tam = get_viewport_rect().size
	var linea = Line2D.new()
	linea.width = 4.0
	linea.default_color = Color(0.2, 0.9, 1.0, 0.75)
	linea.add_point(Vector2(tam.x * 0.5, 0))
	linea.add_point(Vector2(tam.x * 0.5, tam.y))
	add_child(linea)

func _crear_cursor(id_jugador: int) -> void:
	var c = Area2D.new()
	c.set_script(preload("res://scripts/cursor.gd"))
	c.jugador = id_jugador
	c.modo = "webcam"
	c.restringir_zona = es_versus_compartido
	var tam = get_viewport_rect().size
	c.position = Vector2(tam.x * (0.25 if id_jugador == 1 else 0.75), tam.y * 0.5) if es_versus_compartido else tam / 2.0
	var col = CollisionShape2D.new()
	var forma = CircleShape2D.new()
	forma.radius = 25
	col.shape = forma
	c.add_child(col)
	add_child(c)
