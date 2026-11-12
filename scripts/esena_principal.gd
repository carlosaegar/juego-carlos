extends Node2D

@export var duracion_round: float = 30.0

const CENTRO_TIEMPO := Vector2(-11, 234)

const TEXTURAS_ROUND := {
	1: preload("res://assets/sprites/round1_hombre.png"),
	2: preload("res://assets/sprites/round2_hombre.png"),
	3: preload("res://assets/sprites/round3_hombre.png")
}

@onready var round1 = $Round1
@onready var boxeador1 = $boxeador1
@onready var boxeador2 = $boxeador2

var hud: CanvasLayer
var label_tiempo: Label
var label_vida1: Label
var label_vida2: Label
var label_ganador: Label
var label_boost1: Label
var label_boost2: Label
var barra_boost1: ProgressBar
var barra_boost2: ProgressBar

var tiempo_restante: float = 0.0
var round_actual: int = 1
const MAX_ROUNDS: int = 3

var pos_inicial_b1: Vector2
var pos_inicial_b2: Vector2
var tamano_base_cartel: Vector2

func _ready() -> void:
	pos_inicial_b1 = boxeador1.position
	pos_inicial_b2 = boxeador2.position
	tamano_base_cartel = round1.texture.get_size() * round1.scale

	_crear_hud()

	boxeador1.hide()
	boxeador2.hide()
	boxeador1.set_process(false)
	boxeador2.set_process(false)
	hud.visible = false
	set_process(false)

	round1.vuelta_terminada.connect(_on_vuelta_terminada)
	boxeador1.vida_cambiada.connect(_on_vida1_cambiada)
	boxeador2.vida_cambiada.connect(_on_vida2_cambiada)
	boxeador1.boost_cambiado.connect(_on_boost1_cambiado)
	boxeador2.boost_cambiado.connect(_on_boost2_cambiado)

# ---------- HUD (textos y barras en pantalla) ----------

func _crear_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	# J1 arriba a la izquierda (letra más pequeña y color rojo vivo)
	label_vida1 = _crear_label(HORIZONTAL_ALIGNMENT_LEFT, 32, 7)
	label_vida1.add_theme_color_override("font_color", Color(1.0, 0.12, 0.12))
	_colocar(label_vida1, Vector2(0, 0), Vector2(20, 16), Vector2(360, 48))

	label_boost1 = _crear_label(HORIZONTAL_ALIGNMENT_LEFT, 16, 4)
	label_boost1.text = "BOOST"
	_colocar(label_boost1, Vector2(0, 0), Vector2(20, 66), Vector2(150, 20))

	barra_boost1 = _crear_barra_boost()
	_colocar_control(barra_boost1, Vector2(0, 0), Vector2(20, 86), Vector2(150, 12))

	# J2 arriba a la derecha (letra más pequeña y color azul vivo)
	label_vida2 = _crear_label(HORIZONTAL_ALIGNMENT_RIGHT, 32, 7)
	label_vida2.add_theme_color_override("font_color", Color(0.1, 0.55, 1.0))
	_colocar(label_vida2, Vector2(1, 0), Vector2(-380, 16), Vector2(360, 48))

	label_boost2 = _crear_label(HORIZONTAL_ALIGNMENT_RIGHT, 16, 4)
	label_boost2.text = "BOOST"
	_colocar(label_boost2, Vector2(1, 0), Vector2(-170, 66), Vector2(150, 20))

	barra_boost2 = _crear_barra_boost()
	barra_boost2.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	_colocar_control(barra_boost2, Vector2(1, 0), Vector2(-170, 86), Vector2(150, 12))

	# Tiempo en el centro del ring, en la franja negra de abajo
	label_tiempo = _crear_label(HORIZONTAL_ALIGNMENT_CENTER, 56)
	var tam := Vector2(500, 70)
	_colocar(label_tiempo, Vector2(0.5, 0.5), CENTRO_TIEMPO - tam / 2.0, tam)

	# Cartel grande en pantalla para anunciar al ganador final
	label_ganador = _crear_label(HORIZONTAL_ALIGNMENT_CENTER, 64)
	var tam_ganador := Vector2(900, 120)
	_colocar(label_ganador, Vector2(0.5, 0.5), Vector2(0, -140) - tam_ganador / 2.0, tam_ganador)
	label_ganador.visible = false

func _crear_barra_boost() -> ProgressBar:
	var barra := ProgressBar.new()
	barra.min_value = 0.0
	barra.max_value = 100.0
	barra.value = 100.0
	barra.show_percentage = false

	var estilo_fondo := StyleBoxFlat.new()
	estilo_fondo.bg_color = Color(0.15, 0.15, 0.15, 0.85)
	estilo_fondo.border_width_left = 2
	estilo_fondo.border_width_right = 2
	estilo_fondo.border_width_top = 2
	estilo_fondo.border_width_bottom = 2
	estilo_fondo.border_color = Color.BLACK

	var estilo_relleno := StyleBoxFlat.new()
	estilo_relleno.bg_color = Color(0.0, 0.85, 1.0, 1.0)

	barra.add_theme_stylebox_override("background", estilo_fondo)
	barra.add_theme_stylebox_override("fill", estilo_relleno)
	hud.add_child(barra)
	return barra

func _crear_label(alineacion: HorizontalAlignment, tamano_letra: int, grosor_borde: int = 10) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alineacion
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", tamano_letra)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", grosor_borde)
	hud.add_child(label)
	return label

func _colocar(label: Label, ancla: Vector2, desde: Vector2, tamano: Vector2) -> void:
	_colocar_control(label, ancla, desde, tamano)

func _colocar_control(ctrl: Control, ancla: Vector2, desde: Vector2, tamano: Vector2) -> void:
	ctrl.anchor_left = ancla.x
	ctrl.anchor_right = ancla.x
	ctrl.anchor_top = ancla.y
	ctrl.anchor_bottom = ancla.y
	ctrl.offset_left = desde.x
	ctrl.offset_top = desde.y
	ctrl.offset_right = desde.x + tamano.x
	ctrl.offset_bottom = desde.y + tamano.y

# ---------- Flujo de la partida ----------

func _on_vuelta_terminada() -> void:
	boxeador1.position = pos_inicial_b1
	boxeador2.position = pos_inicial_b2

	boxeador1.show()
	boxeador2.show()
	boxeador1.set_process(true)
	boxeador2.set_process(true)

	tiempo_restante = duracion_round
	_actualizar_tiempo()
	_actualizar_vida1(boxeador1.vida)
	_actualizar_vida2(boxeador2.vida)
	hud.visible = true
	set_process(true)

func _process(delta: float) -> void:
	tiempo_restante = max(tiempo_restante - delta, 0.0)
	_actualizar_tiempo()
	if tiempo_restante <= 0.0:
		_terminar_round()

func _on_vida1_cambiada(vida: int) -> void:
	_actualizar_vida1(vida)
	if vida <= 0:
		_terminar_combate()

func _on_vida2_cambiada(vida: int) -> void:
	_actualizar_vida2(vida)
	if vida <= 0:
		_terminar_combate()

func _on_boost1_cambiado(valor: float, maximo: float) -> void:
	barra_boost1.max_value = maximo
	barra_boost1.value = valor
	var estilo := barra_boost1.get_theme_stylebox("fill") as StyleBoxFlat
	if valor >= maximo:
		estilo.bg_color = Color(0.0, 0.85, 1.0, 1.0)
	else:
		estilo.bg_color = Color(1.0, 0.55, 0.0, 1.0)

func _on_boost2_cambiado(valor: float, maximo: float) -> void:
	barra_boost2.max_value = maximo
	barra_boost2.value = valor
	var estilo := barra_boost2.get_theme_stylebox("fill") as StyleBoxFlat
	if valor >= maximo:
		estilo.bg_color = Color(0.0, 0.85, 1.0, 1.0)
	else:
		estilo.bg_color = Color(1.0, 0.55, 0.0, 1.0)

func _actualizar_tiempo() -> void:
	var segundos := ceili(tiempo_restante)
	label_tiempo.text = "R%d - %d:%02d" % [round_actual, floori(segundos / 60.0), segundos % 60]

func _actualizar_vida1(vida: int) -> void:
	label_vida1.text = "J1: " + str(vida) + " ptos"

func _actualizar_vida2(vida: int) -> void:
	label_vida2.text = "J2: " + str(vida) + " ptos"

func _terminar_round() -> void:
	set_process(false)
	boxeador1.set_process(false)
	boxeador2.set_process(false)

	if round_actual < MAX_ROUNDS:
		round_actual += 1
		boxeador1.hide()
		boxeador2.hide()
		hud.visible = false

		if TEXTURAS_ROUND.has(round_actual):
			round1.texture = TEXTURAS_ROUND[round_actual]
			var nuevo_tamano: Vector2 = round1.texture.get_size()
			round1.scale = tamano_base_cartel / nuevo_tamano

		round1.iniciar_vuelta()
	else:
		_terminar_combate()

func _terminar_combate() -> void:
	set_process(false)
	boxeador1.set_process(false)
	boxeador2.set_process(false)

	boxeador1.show()
	boxeador2.show()
	boxeador1.position = Vector2(-60, 0)
	boxeador2.position = Vector2(60, 0)

	label_tiempo.text = "FIN DEL COMBATE"
	label_ganador.visible = true

	if boxeador1.vida > boxeador2.vida:
		label_ganador.text = "¡GANADOR: JUGADOR 1!"
	elif boxeador2.vida > boxeador1.vida:
		label_ganador.text = "¡GANADOR: JUGADOR 2!"
	else:
		label_ganador.text = "¡EMPATE!"
