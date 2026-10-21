extends Control

const SAVE_DIRECTORY = "user://saves/"

@onready var save_list: ItemList = find_child("SaveList", true, false)
@onready var new_save_button: Button = find_child("NewSaveButton", true, false)
@onready var confirm_button: Button = find_child("ConfirmButton", true, false)
@onready var cancel_button: Button = find_child("CancelButton", true, false)
@onready var eliminar_button: Button = find_child("EliminarPartida", true, false)
@onready var title_label: Label = find_child("TitleLabel", true, false)

var load_game_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)
	
	# Si el juego NO está pausado, asumimos que venimos del Menú Principal -> Creamos botón de Cargar
	if not get_tree().paused:
		_crear_boton_cargar_exclusivo()
		
	_actualizar_lista_slots()
	
	if new_save_button:
		new_save_button.process_mode = Node.PROCESS_MODE_ALWAYS
		new_save_button.pressed.connect(_on_crear_nueva_partida)
	if confirm_button:
		confirm_button.process_mode = Node.PROCESS_MODE_ALWAYS
		confirm_button.pressed.connect(_on_sobrescribir_partida)
	if cancel_button:
		cancel_button.process_mode = Node.PROCESS_MODE_ALWAYS
		cancel_button.pressed.connect(_on_salir)
	if eliminar_button:
		eliminar_button.process_mode = Node.PROCESS_MODE_ALWAYS
		eliminar_button.pressed.connect(_on_eliminar_partida)

func _crear_boton_cargar_exclusivo() -> void:
	if not confirm_button:
		return
		
	load_game_button = Button.new()
	load_game_button.text = "Load Game"
	load_game_button.custom_minimum_size = confirm_button.custom_minimum_size
	load_game_button.size_flags_horizontal = confirm_button.size_flags_horizontal
	
	var padre = confirm_button.get_parent()
	padre.add_child(load_game_button)
	padre.move_child(load_game_button, confirm_button.get_index())
	
	confirm_button.visible = false
	if new_save_button:
		new_save_button.visible = false
		
	load_game_button.pressed.connect(_on_cargar_partida_seleccionada)

func _actualizar_lista_slots() -> void:
	if not save_list:
		return
		
	save_list.clear()
	var partidas_encontradas = 0
	
	var dir = DirAccess.open(SAVE_DIRECTORY)
	if dir:
		dir.list_dir_begin()
		var archivo_nombre = dir.get_next()
		
		while archivo_nombre != "":
			if not dir.current_is_dir() and archivo_nombre.begins_with("partida_") and archivo_nombre.ends_with(".json"):
				var ruta_completa = SAVE_DIRECTORY + archivo_nombre
				var archivo = FileAccess.open(ruta_completa, FileAccess.READ)
				if archivo:
					var texto = archivo.get_line()
					archivo.close()
					var datos = JSON.parse_string(texto)
					if datos is Dictionary:
						var nivel = datos.get("ruta_nivel", "level").get_file()
						var fecha = datos.get("fecha_guardado", "Unknown Date")
						var modo_guardado = datos.get("modo_juego", "solo")
						var id_str = archivo_nombre.trim_prefix("partida_").trim_suffix(".json")
						
						var modo_texto = "[1 Player]"
						if modo_guardado == "versus" or modo_guardado == "2":
							modo_texto = "[2 Players]"
						
						# AQUÍ ESTÁ EL CAMBIO: Saved Game en lugar de Save Slot
						var idx = save_list.add_item("Saved Game %s | %s | %s | %s" % [id_str, modo_texto, nivel, fecha])
						save_list.set_item_metadata(idx, ruta_completa)
						partidas_encontradas += 1
			archivo_nombre = dir.get_next()
		dir.list_dir_end()
		
	if partidas_encontradas == 0:
		if title_label:
			title_label.text = "LOAD GAME (NO SAVED GAMES)"
		save_list.add_item("(NO SAVED GAMES)")
	else:
		if title_label:
			title_label.text = "LOAD GAME"

func _on_cargar_partida_seleccionada() -> void:
	var items_seleccionados = save_list.get_selected_items()
	if items_seleccionados.size() == 0:
		print("⚠️ Please select a save slot to load.")
		return
		
	var idx = items_seleccionados[0]
	var ruta_archivo = save_list.get_item_metadata(idx)
	
	if not ruta_archivo or not FileAccess.file_exists(ruta_archivo):
		return
		
	var archivo = FileAccess.open(ruta_archivo, FileAccess.READ)
	if archivo:
		var texto = archivo.get_line()
		archivo.close()
		
		var datos = JSON.parse_string(texto)
		if datos is Dictionary and datos.has("ruta_nivel"):
			var nivel_a_cargar = datos["ruta_nivel"]
			
			if datos.has("modo_juego"):
				Global.modo = datos["modo_juego"]
			
			# (Opcional) Podemos guardar la ruta del archivo actual en una variable global o temporal 
			# para que el nivel la lea al nacer, por ejemplo: Global.partida_cargada_path = ruta_archivo
			Global.partida_cargada_path = ruta_archivo
			
			get_tree().paused = false
			get_tree().change_scene_to_file(nivel_a_cargar)
			queue_free()

func _on_crear_nueva_partida() -> void:
	var escena_actual = get_tree().current_scene
	if not escena_actual:
		return
		
	var tiempo_actual = 0.0
	if escena_actual.has_method("obtener_tiempo_restante"):
		tiempo_actual = escena_actual.obtener_tiempo_restante()
	elif "tiempo_restante" in escena_actual:
		tiempo_actual = escena_actual.tiempo_restante

	var slot_id = 1
	while FileAccess.file_exists(SAVE_DIRECTORY + "partida_%03d.json" % slot_id):
		slot_id += 1
		
	var ruta_archivo = SAVE_DIRECTORY + "partida_%03d.json" % slot_id
	var fecha_hora_actual = Time.get_datetime_string_from_system(false, true)
	
	var datos = {
		"slot_id": slot_id,
		"ruta_nivel": escena_actual.scene_file_path,
		"modo_juego": Global.modo,
		"tiempo_guardado": tiempo_actual,
		"fecha_guardado": fecha_hora_actual
	}
	
	var archivo = FileAccess.open(ruta_archivo, FileAccess.WRITE)
	if archivo:
		archivo.store_line(JSON.stringify(datos))
		archivo.close()
		print("💾 New save created in slot: ", slot_id)
		
	get_tree().paused = false
	queue_free()

func _on_sobrescribir_partida() -> void:
	var items_seleccionados = save_list.get_selected_items()
	if items_seleccionados.size() == 0:
		return
	var idx = items_seleccionados[0]
	var ruta_archivo = save_list.get_item_metadata(idx)
	if not ruta_archivo:
		return
		
	var escena_actual = get_tree().current_scene
	if not escena_actual:
		return
		
	var tiempo_actual = 0.0
	if escena_actual.has_method("obtener_tiempo_restante"):
		tiempo_actual = escena_actual.obtener_tiempo_restante()
	elif "tiempo_restante" in escena_actual:
		tiempo_actual = escena_actual.tiempo_restante
		
	var fecha_hora_actual = Time.get_datetime_string_from_system(false, true)
	var datos = {
		"ruta_nivel": escena_actual.scene_file_path,
		"modo_juego": Global.modo,
		"tiempo_guardado": tiempo_actual,
		"fecha_guardado": fecha_hora_actual
	}
	
	var archivo = FileAccess.open(ruta_archivo, FileAccess.WRITE)
	if archivo:
		archivo.store_line(JSON.stringify(datos))
		archivo.close()
		print("🔄 Game overwritten successfully.")
		
	get_tree().paused = false
	queue_free()

func _on_salir() -> void:
	queue_free()

func _on_eliminar_partida() -> void:
	var items_seleccionados = save_list.get_selected_items()
	if items_seleccionados.size() > 0:
		var idx = items_seleccionados[0]
		var ruta_archivo = save_list.get_item_metadata(idx)
		if ruta_archivo and FileAccess.file_exists(ruta_archivo):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_archivo))
			print("🗑️ Save slot deleted.")
			
	_actualizar_lista_slots()
