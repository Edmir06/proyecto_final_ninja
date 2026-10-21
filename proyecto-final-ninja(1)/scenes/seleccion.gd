extends Control

const ESCENA_NOMBRES = "res://scenes/menu.tscn"
const FONDO = "res://assets/tech_background.png"

const CIAN = Color("19c8ff")

func _ready() -> void:
	if ResourceLoader.exists(FONDO):
		var fondo = TextureRect.new()
		fondo.texture = load(FONDO)
		fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fondo.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(fondo)
	else:
		var color = ColorRect.new()
		color.color = Color("07131f")
		color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(color)

	var caja = VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 20)
	add_child(caja)

	var titulo = Label.new()
	titulo.text = "TECH NINJA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 80)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	titulo.add_theme_color_override("font_outline_color", CIAN)
	titulo.add_theme_constant_override("outline_size", 6)
	caja.add_child(titulo)

	var subtitulo = Label.new()
	subtitulo.text = "SELECT GAME MODE"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 26)
	subtitulo.add_theme_color_override("font_color", CIAN)
	caja.add_child(subtitulo)

	var espacio = Control.new()
	espacio.custom_minimum_size = Vector2(0, 10)
	caja.add_child(espacio)

	var b1 = _crear_boton("1 Player", caja)
	var b2 = _crear_boton("2 Players", caja)
	var b3 = _crear_boton("EXIT", caja)

	b1.pressed.connect(_elegir.bind("solo"))
	b2.pressed.connect(_elegir.bind("versus"))
	b3.pressed.connect(get_tree().quit)

	b1.grab_focus()

func _crear_boton(texto: String, padre: Control) -> Button:
	var b = Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(340, 62)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", CIAN)
	b.add_theme_color_override("font_focus_color", CIAN)
	b.add_theme_stylebox_override("normal", _estilo(Color(0.02, 0.08, 0.14, 0.85), CIAN, 2))
	b.add_theme_stylebox_override("hover", _estilo(Color(0.05, 0.2, 0.32, 0.95), CIAN, 3))
	b.add_theme_stylebox_override("pressed", _estilo(Color(0.1, 0.35, 0.5, 1.0), Color.WHITE, 3))
	b.add_theme_stylebox_override("focus", _estilo(Color(0.05, 0.2, 0.32, 0.95), CIAN, 3))
	padre.add_child(b)
	return b

func _estilo(relleno: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = relleno
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(8)
	return s

func _elegir(modo: String) -> void:
	Global.modo = modo
	get_tree().change_scene_to_file(ESCENA_NOMBRES)
