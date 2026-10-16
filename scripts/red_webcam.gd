extends Node

var udp := PacketPeerUDP.new()
var puerto := 4242

var pos_j1 := Vector2.ZERO
var pos_j2 := Vector2.ZERO

var j1_detectado: bool = false
var j2_detectado: bool = false

func _ready() -> void:
	if udp.bind(puerto) != OK:
		print("Error al abrir el puerto UDP ", puerto)
	else:
		print("Servidor UDP de Godot escuchando en el puerto ", puerto)

func _process(_delta: float) -> void:
	while udp.get_available_packet_count() > 0:
		var paquete = udp.get_packet()
		var texto = paquete.get_string_from_utf8()
		var json = JSON.new()
		
		if json.parse(texto) == OK:
			var datos = json.data
			var w_py = 640.0
			var h_py = 480.0
			var tam_pantalla = get_viewport().get_visible_rect().size
			
			if datos.has("1"):
				j1_detectado = true
				pos_j1.x = (datos["1"]["x"] / w_py) * tam_pantalla.x
				pos_j1.y = (datos["1"]["y"] / h_py) * tam_pantalla.y
			else:
				j1_detectado = false
				
			if datos.has("2"):
				j2_detectado = true
				pos_j2.x = (datos["2"]["x"] / w_py) * tam_pantalla.x
				pos_j2.y = (datos["2"]["y"] / h_py) * tam_pantalla.y
			else:
				j2_detectado = false
