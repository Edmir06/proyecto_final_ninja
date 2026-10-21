extends CanvasLayer
class_name IntroBienvenida

signal terminado

const TIEMPO_INTRO: float = 7.0

func _ready() -> void:
	layer = 20

	# Fondo oscuro semitransparente sobre toda la pantalla
	var oscurecedor = ColorRect.new()
	oscurecedor.set_anchors_preset(Control.PRESET_FULL_RECT)
	oscurecedor.color = Color(0, 0, 0, 0.55)
	oscurecedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(oscurecedor)

	# Panel de diálogo estilo madera, centrado en la ventana global
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.11, 0.04, 0.95)
	estilo.border_color = Color(0.55, 0.32, 0.12)
	estilo.set_border_width_all(8)
	estilo.set_corner_radius_all(14)
	estilo.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", estilo)
	add_child(panel)

	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	panel.add_child(caja)

	var titulo = Label.new()
	titulo.text = "NINJAS IN ACTION!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 38)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	caja.add_child(titulo)

	var mensaje = Label.new()
	mensaje.text = "Move your hands in front of the camera and destroy every object."
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mensaje.add_theme_font_size_override("font_size", 22)
	mensaje.add_theme_color_override("font_color", Color(1, 1, 1))
	mensaje.custom_minimum_size = Vector2(480, 0)
	caja.add_child(mensaje)

	var lema = Label.new()
	lema.text = "Let the Ninja battle begin!"
	lema.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lema.add_theme_font_size_override("font_size", 26)
	lema.add_theme_color_override("font_color", Color(0.95, 0.75, 0.4))
	caja.add_child(lema)

	get_tree().create_timer(TIEMPO_INTRO).timeout.connect(_terminar)

func _terminar() -> void:
	terminado.emit()
	queue_free()
