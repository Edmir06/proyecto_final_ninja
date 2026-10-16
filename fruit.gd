extends RigidBody2D

var datos_frutas = [
	{
		"entera": preload("res://assets/kiwi.png"),
		"izq": preload("res://assets/kiwi izq.png"),
		"der": preload("res://assets/kiwi der.png"),
		"es_basura": false,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/manzana2.png"),
		"izq": preload("res://assets/manzana izq.png"),
		"der": preload("res://assets/manzana der.png"),
		"es_basura": false,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/sandia.png"),
		"izq": preload("res://assets/sandia izq.png"),
		"der": preload("res://assets/sandia der.png"),
		"es_basura": false,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/bolsa entere.png"),
		"izq": preload("res://assets/bolsa izq.png"),
		"der": preload("res://assets/bolsa der.png"),
		"es_basura": true,
		"escala": Vector2(0.4, 0.4)
	},
	{
		"entera": preload("res://assets/botella entera.png"),
		"izq": preload("res://assets/botella izq.png"),
		"der": preload("res://assets/botella der.png"),
		"es_basura": true,
		"escala": Vector2(0.4, 0.4)
	}
]

var fruta_actual: Dictionary
var escena_mitad = preload("res://scenes/fruit_half.tscn")

@export var fuerza_impulso: Vector2 = Vector2(150, -750)
var frenado_aplicado: bool = false
var ya_cortada: bool = false

func _ready() -> void:
	add_to_group("frutas")
	fruta_actual = datos_frutas.pick_random()
	$Sprite2D.texture = fruta_actual["entera"]
	
	var esc = fruta_actual.get("escala", Vector2(1, 1))
	$Sprite2D.scale = esc
	$CollisionShape2D.scale = esc
	
	apply_central_impulse(Vector2(randf_range(-100, 100), fuerza_impulso.y))

func _physics_process(_delta: float) -> void:
	if not frenado_aplicado and linear_velocity.y >= -50 and linear_velocity.y <= 50:
		frenado_aplicado = true
		gravity_scale = 0.2
		await get_tree().create_timer(0.5).timeout
		gravity_scale = 1.0

	if position.y > 800:
		queue_free()

func cortar(jugador: int) -> void:
	if ya_cortada:
		return
	ya_cortada = true

	var nodo_actual = get_parent()
	while nodo_actual != null and not nodo_actual.has_method("sumar_punto"):
		nodo_actual = nodo_actual.get_parent()
		
	if nodo_actual != null:
		if fruta_actual.get("es_basura", false):
			nodo_actual.restar_punto(jugador)
		else:
			nodo_actual.sumar_punto(jugador)

	var esc = fruta_actual.get("escala", Vector2(1, 1))
	crear_mitad(fruta_actual["izq"], Vector2(-150, -200), -15, esc)
	crear_mitad(fruta_actual["der"], Vector2(150, -200), 15, esc)
	
	queue_free()

func crear_mitad(textura: Texture2D, impulso: Vector2, offset_x: float, esc: Vector2) -> void:
	var mitad = escena_mitad.instantiate()
	mitad.position = position + Vector2(offset_x, 0)
	
	var sprite_mitad = mitad.get_node("Sprite2D")
	sprite_mitad.texture = textura
	sprite_mitad.scale = esc
	
	get_parent().add_child(mitad)
	mitad.apply_central_impulse(impulso)
