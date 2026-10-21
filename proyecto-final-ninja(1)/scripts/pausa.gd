extends Node

var canvas_layer: CanvasLayer
var panel_fondo: ColorRect
var contenedor: VBoxContainer
var boton_pausa_flotante: TextureButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128 
	add_child(canvas_layer)
	
	_construir_interfaz()
	panel_fondo.visible = false
	boton_pausa_flotante.visible = false

# Revisión segura de la escena actual
func _process(_delta: float) -> void:
	var escena_actual = get_tree().current_scene
	if not escena_actual:
		return
		
	var ruta_archivo = escena_actual.scene_file_path
	
	if "menu.tscn" in ruta_archivo or "select_level.tscn" in ruta_archivo or "seleccion.tscn" in ruta_archivo:
		boton_pausa_flotante.visible = false
		if get_tree().paused:
			_cerrar_pausa() # Forzamos a cerrar la pausa si estamos en menús
	else:
		if not get_tree().paused and panel_fondo.visible == false:
			boton_pausa_flotante.visible = true

func _input(event: InputEvent) -> void:
	var escena_actual = get_tree().current_scene
	if not escena_actual:
		return
		
	var ruta_archivo = escena_actual.scene_file_path
	if "menu.tscn" in ruta_archivo or "select_level.tscn" in ruta_archivo or "seleccion.tscn" in ruta_archivo:
		return

	if event.is_action_pressed("ui_cancel"):
		_toggle_pausa()

func _toggle_pausa() -> void:
	var esta_pausado = get_tree().paused
	get_tree().paused = not esta_pausado
	if panel_fondo:
		panel_fondo.visible = not esta_pausado
	
	if boton_pausa_flotante:
		var escena_actual = get_tree().current_scene
		if escena_actual:
			var ruta_archivo = escena_actual.scene_file_path
			if not ("menu.tscn" in ruta_archivo or "select_level.tscn" in ruta_archivo or "seleccion.tscn" in ruta_archivo):
				# El botón se queda visible siempre que estemos en el nivel de juego
				boton_pausa_flotante.visible = true

func _cerrar_pausa() -> void:
	get_tree().paused = false
	if panel_fondo:
		panel_fondo.visible = false
	if boton_pausa_flotante:
		boton_pausa_flotante.visible = false

func _construir_interfaz() -> void:
	panel_fondo = ColorRect.new()
	panel_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_fondo.color = Color(0, 0, 0, 0.8)
	canvas_layer.add_child(panel_fondo)

	contenedor = VBoxContainer.new()
	contenedor.set_anchors_preset(Control.PRESET_CENTER)
	contenedor.custom_minimum_size = Vector2(300, 0)
	panel_fondo.add_child(contenedor)

	var titulo = Label.new()
	titulo.text = "PAUSE MENU"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 40)
	contenedor.add_child(titulo)

	var espacio = Control.new()
	espacio.custom_minimum_size = Vector2(0, 25)
	contenedor.add_child(espacio)

	_crear_boton("Resume", _on_resume_pressed)
	_crear_boton("Reset", _on_reset_pressed)
	_crear_boton("Load", _on_load_pressed)
	_crear_boton("Main Menu", _on_main_menu_pressed)
	_crear_boton("Quit Game", _on_quit_game_pressed)

	boton_pausa_flotante = TextureButton.new()
	boton_pausa_flotante.texture_normal = load("res://assets/icono pausa.png")
	boton_pausa_flotante.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	boton_pausa_flotante.offset_left = -90
	boton_pausa_flotante.offset_top = 20
	boton_pausa_flotante.offset_right = -20
	boton_pausa_flotante.offset_bottom = 90
	boton_pausa_flotante.ignore_texture_size = true
	boton_pausa_flotante.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	boton_pausa_flotante.process_mode = Node.PROCESS_MODE_ALWAYS
	boton_pausa_flotante.pressed.connect(_toggle_pausa)
	canvas_layer.add_child(boton_pausa_flotante)

func _crear_boton(texto: String, funcion_a_conectar: Callable) -> void:
	var boton = Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(0, 50)
	boton.add_theme_font_size_override("font_size", 24)
	boton.pressed.connect(funcion_a_conectar)
	contenedor.add_child(boton)

# --- ACCIONES LIMPIAS ---

func _on_resume_pressed() -> void:
	_toggle_pausa()

func _on_reset_pressed() -> void:
	_cerrar_pausa()
	get_tree().reload_current_scene()

func _on_load_pressed() -> void:
	_cerrar_pausa()
	get_tree().change_scene_to_file("res://scenes/select_level.tscn")

func _on_main_menu_pressed() -> void:
	_cerrar_pausa()
	get_tree().change_scene_to_file("res://scenes/seleccion.tscn")

func _on_quit_game_pressed() -> void:
	get_tree().quit()
