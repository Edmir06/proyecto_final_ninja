extends Control

var escena_partida = preload("res://scenes/main.tscn")
var resultados := {}
var texto_final: Label
var partidas: Array = []

func _ready() -> void:
	var caja = HBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override("separation", 4)
	add_child(caja)

	for id in [1, 2]:
		var cont = SubViewportContainer.new()
		cont.stretch = true
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
		caja.add_child(cont)

		var vp = SubViewport.new()
		cont.add_child(vp)

		var partida = escena_partida.instantiate()
		partida.jugador_id = id
		partida.es_ia = (id == 2)   # J2 = IA (cámbialo a false para teclado)
		partida.entrada_bloqueada = true
		partida.partida_terminada.connect(_on_partida_terminada)
		vp.add_child(partida)
		partidas.append(partida)

	# Texto del ganador, centrado arriba
	var capa = CanvasLayer.new()
	add_child(capa)
	texto_final = Label.new()
	texto_final.set_anchors_preset(Control.PRESET_CENTER_TOP)
	texto_final.add_theme_font_size_override("font_size", 40)
	capa.add_child(texto_final)

	# Cartel de bienvenida único, centrado sobre ambas pantallas
	var intro = IntroBienvenida.new()
	add_child(intro)
	intro.terminado.connect(_on_intro_terminada)

func _on_intro_terminada() -> void:
	for partida in partidas:
		if is_instance_valid(partida):
			partida.iniciar_partida()

func _on_partida_terminada(jugador: int, puntos: int) -> void:
	resultados[jugador] = puntos
	if resultados.size() < 2:
		return
	if resultados[1] > resultados[2]:
		texto_final.text = "¡GANA JUGADOR 1!"
	elif resultados[2] > resultados[1]:
		texto_final.text = "¡GANA JUGADOR 2!"
	else:
		texto_final.text = "¡EMPATE!"
