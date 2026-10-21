extends Node

var nombres := {1: "Jugador 1", 2: "Jugador 2"}
var modo: String = "versus"    # "solo" o "versus"

var nivel_actual: int = 1

# Definimos ambas por compatibilidad con los scripts de nivel:
var nivel_desbloqueado: int = 1
var max_nivel_solo: int = 1
var max_nivel_versus: int = 1
