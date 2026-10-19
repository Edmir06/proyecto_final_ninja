extends Control

var escena_partida = preload("res://scenes/main.tscn")
var resultados := {}
var texto_final: Label

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
		vp.world_2d = World2D.new()   # física separada para cada jugador
		cont.add_child(vp)

		var partida = escena_partida.instantiate()
		partida.jugador_id = id
		partida.es_ia = false  # J2 = IA (pon false para teclado)
		partida.partida_terminada.connect(_on_partida_terminada)
		vp.add_child(partida)

	var capa = CanvasLayer.new()
	add_child(capa)
	texto_final = Label.new()
	texto_final.set_anchors_preset(Control.PRESET_CENTER_TOP)

	texto_final.add_theme_font_size_override("font_size", 40)
	capa.add_child(texto_final)

func _on_partida_terminada(jugador: int, puntos: int) -> void:
	resultados[jugador] = puntos
	if resultados.size() < 2:
		return
	if resultados[1] > resultados[2]:
		texto_final.text = "¡WINNER " + Global.nombres[1].to_upper() + "!"
	elif resultados[2] > resultados[1]:
		texto_final.text = "¡WINNER" + Global.nombres[2].to_upper() + "!"
	else:
		texto_final.text = "¡DRAW!"
