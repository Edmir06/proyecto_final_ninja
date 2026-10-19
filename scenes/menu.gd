extends Control

@onready var nombre_j1: LineEdit = %NombreJ1
@onready var nombre_j2: LineEdit = %NombreJ2
@onready var go_button: Button = $Button
@onready var title_label: Label = $Label

func _ready() -> void:
	go_button.pivot_offset = go_button.size / 2
	title_label.pivot_offset = title_label.size / 2
	animar_go()
	animar_titulo()

func animar_go() -> void:
	while true:
		var t1 = create_tween()
		t1.set_parallel(true)
		t1.tween_property(go_button, "scale", Vector2(1.08, 1.08), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t1.tween_property(go_button, "modulate", Color(0.6, 0.9, 1.0, 1.0), 0.55)
		await t1.finished

		var t2 = create_tween()
		t2.set_parallel(true)
		t2.tween_property(go_button, "scale", Vector2(1.0, 1.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t2.tween_property(go_button, "modulate", Color(1, 1, 1, 1), 0.55)
		await t2.finished

func animar_titulo() -> void:
	var pos_original = title_label.position
	title_label.modulate.a = 0.0
	title_label.position = pos_original + Vector2(0, -20)

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.8)
	t.tween_property(title_label, "position", pos_original, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_button_pressed() -> void:
	var n1 = nombre_j1.text.strip_edges()
	var n2 = nombre_j2.text.strip_edges()
	Global.nombres[1] = n1 if n1 != "" else "Jugador 1"
	Global.nombres[2] = n2 if n2 != "" else "Jugador 2"
	get_tree().change_scene_to_file("res://scripts/versus.tscn")
