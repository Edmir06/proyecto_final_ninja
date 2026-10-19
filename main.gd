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
var juego_terminado: bool = false

func _ready() -> void:
	timer_lanzamiento.timeout.connect(_on_timer_lanzamiento_timeout)
	timer_juego.timeout.connect(_on_timer_juego_timeout)
	_crear_cursor()

	# --- Marcador de Puntos ---
	texto_puntos.visible = true
	texto_puntos.position = Vector2(20, 20)
	texto_puntos.add_theme_font_size_override("font_size", 28)
	texto_puntos.text = Global.nombres[jugador_id] + ": 0"
	
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
	nueva_fruta.position = Vector2(randf_range(ancho * 0.1, ancho * 0.9), spawneador.position.y)
	add_child(nueva_fruta)

func sumar_punto(_jugador: int = 0) -> void:
	if not juego_terminado:
		puntos += 1
		texto_puntos.text = Global.nombres[jugador_id] + ": " + str(puntos)

func restar_punto(_jugador: int = 0) -> void:
	if not juego_terminado:
		puntos = max(0, puntos - 1)
		texto_puntos.text = Global.nombres[jugador_id] + ": " + str(puntos)

func _on_timer_juego_timeout() -> void:
	juego_terminado = true
	timer_lanzamiento.stop()
	
	texto_puntos.visible = false
	
	texto_tiempo.add_theme_font_size_override("font_size", 42)
	texto_tiempo.text = "¡FINISH!\nPuntos: " + str(puntos)
	texto_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_tiempo.position = Vector2(100, 220)
	
	partida_terminada.emit(jugador_id, puntos)

func _crear_cursor() -> void:
	var c = Area2D.new()
	c.set_script(preload("res://scripts/cursor.gd"))
	c.jugador = jugador_id
	c.modo = "webcam"
	c.position = get_viewport_rect().size / 2
	var col = CollisionShape2D.new()
	var forma = CircleShape2D.new()
	forma.radius = 25
	col.shape = forma
	c.add_child(col)
	add_child(c)
