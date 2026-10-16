extends Control

@onready var nombre_j1: LineEdit = %NombreJ1
@onready var nombre_j2: LineEdit = %NombreJ2

func _on_button_pressed() -> void:
	var n1 = nombre_j1.text.strip_edges()
	var n2 = nombre_j2.text.strip_edges()
	Global.nombres[1] = n1 if n1 != "" else "Jugador 1"
	Global.nombres[2] = n2 if n2 != "" else "Jugador 2"
	get_tree().change_scene_to_file("res://scripts/versus.tscn")
