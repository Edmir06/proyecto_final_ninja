extends Control

@onready var btn_1: Button = $HBoxContainer/Button
@onready var btn_2: Button = $HBoxContainer/Button2
@onready var btn_3: Button = $HBoxContainer/Button3
@onready var btn_extra: Button = $HBoxContainer/Button4

func _ready() -> void:
	var nivel_max = Global.nivel_desbloqueado

	# Nivel 1
	btn_1.disabled = false
	if nivel_max > 1:
		btn_1.text = "1 ✓"
		# Pintamos el texto de verde brillante para que destaque
		btn_1.add_theme_color_override("font_color", Color(0.1, 0.9, 0.2))
	else:
		btn_1.text = "1"
		btn_1.remove_theme_color_override("font_color")

	# Nivel 2
	btn_2.disabled = nivel_max < 2
	if btn_2.disabled:
		btn_2.text = "🔒"
		btn_2.remove_theme_color_override("font_color")
	elif nivel_max > 2:
		btn_2.text = "2 ✓"
		btn_2.add_theme_color_override("font_color", Color(0.1, 0.9, 0.2))
	else:
		btn_2.text = "2"
		btn_2.remove_theme_color_override("font_color")

	# Nivel 3
	btn_3.disabled = nivel_max < 3
	if btn_3.disabled:
		btn_3.text = "🔒"
		btn_3.remove_theme_color_override("font_color")
	else:
		btn_3.text = "3"
		btn_3.remove_theme_color_override("font_color")

	# Botón extra: Bloqueado
	if btn_extra:
		btn_extra.text = "🔒"
		btn_extra.disabled = true

	# Conectamos las señales de los botones
	btn_1.pressed.connect(_on_nivel_seleccionado.bind(1))
	btn_2.pressed.connect(_on_nivel_seleccionado.bind(2))
	btn_3.pressed.connect(_on_nivel_seleccionado.bind(3))

func _on_nivel_seleccionado(nivel: int) -> void:
	Global.nivel_actual = nivel
	
	if nivel == 1:
		get_tree().change_scene_to_file("res://scenes/level1.tscn")
	elif nivel == 2:
		get_tree().change_scene_to_file("res://scenes/level2.tscn")
	elif nivel == 3:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
