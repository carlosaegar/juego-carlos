extends Sprite2D

signal vida_cambiada(nueva_vida: int)
signal boost_cambiado(valor: float, maximo: float)

@export var Velocidad: float = 300.0
@export var vida: int = 100
@export var Dano: int = 10

@export var velocidad_boost: float = 1500.0
@export var duracion_boost: float = 0.22
@export var cooldown_boost: float = 3.0

const LIMITE_ARRIBA := -210.0
const LIMITE_ABAJO := 130.0
const CENTRO_RING := Vector2(0.0, -40.0)

var atacando: bool = false
var tecla_ataque_pulsada: bool = false
var rebotando: bool = false

# Variables del boost
var haciendo_boost: bool = false
var direccion_boost: Vector2 = Vector2.ZERO
var tiempo_recarga_boost: float = 0.0
var ultima_tecla: int = -1
var tiempo_desde_ultimo_toque: float = 0.0
var estado_teclas_mov: Dictionary = {
	KEY_UP: false,
	KEY_DOWN: false,
	KEY_LEFT: false,
	KEY_RIGHT: false
}

@onready var colision_puno = $HitboxPuno/CollisionShape2D
@onready var hitbox_puno = $HitboxPuno

func _ready():
	colision_puno.disabled = false
	hitbox_puno.monitoring = true
	$Hurtbox.monitorable = true
	$Hurtbox/CollisionShape2D.disabled = false
	set_process(true)

func _process(delta: float):
	# 1. Gestión del cooldown de la barra de boost
	if tiempo_recarga_boost > 0.0:
		tiempo_recarga_boost = max(0.0, tiempo_recarga_boost - delta)
		boost_cambiado.emit(cooldown_boost - tiempo_recarga_boost, cooldown_boost)

	if tiempo_desde_ultimo_toque > 0.0:
		tiempo_desde_ultimo_toque -= delta
		if tiempo_desde_ultimo_toque <= 0.0:
			ultima_tecla = -1

	# Si está rebotando contra las cuerdas, bloqueamos temporalmente el control
	if rebotando:
		return

	# 2. Detectar doble pulsación en flechas
	_comprobar_doble_toque(KEY_UP, Vector2.UP)
	_comprobar_doble_toque(KEY_DOWN, Vector2.DOWN)
	_comprobar_doble_toque(KEY_LEFT, Vector2.LEFT)
	_comprobar_doble_toque(KEY_RIGHT, Vector2.RIGHT)

	# 3. Movimiento normal o impulso del boost
	if haciendo_boost:
		position += direccion_boost * velocidad_boost * delta
	else:
		var direccion = Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_RIGHT):
			direccion.x += 1
		if Input.is_physical_key_pressed(KEY_LEFT):
			direccion.x -= 1
		if Input.is_physical_key_pressed(KEY_DOWN):
			direccion.y += 1
		if Input.is_physical_key_pressed(KEY_UP):
			direccion.y -= 1

		position += direccion.normalized() * Velocidad * delta

	# 4. Límites del ring (arriba, abajo y laterales con perspectiva)
	var factor_altura := inverse_lerp(LIMITE_ARRIBA, LIMITE_ABAJO, clamp(position.y, LIMITE_ARRIBA, LIMITE_ABAJO))
	var limite_x := lerpf(265.0, 360.0, factor_altura)

	var toco_vertical := position.y <= LIMITE_ARRIBA or position.y >= LIMITE_ABAJO
	var toco_horizontal := position.x <= -limite_x or position.x >= limite_x

	if toco_vertical or toco_horizontal:
		position.y = clamp(position.y, LIMITE_ARRIBA + 2.0, LIMITE_ABAJO - 2.0)
		position.x = clamp(position.x, -limite_x + 2.0, limite_x - 2.0)
		_rebotar_cuerdas(toco_horizontal, toco_vertical)
		return

	# 5. Ataque con un solo toque
	var ataque_ahora = Input.is_physical_key_pressed(KEY_ENTER) or Input.is_physical_key_pressed(KEY_P)
	if ataque_ahora and not tecla_ataque_pulsada and not atacando:
		golpear()
	tecla_ataque_pulsada = ataque_ahora

func _rebotar_cuerdas(rebote_x: bool, rebote_y: bool) -> void:
	rebotando = true
	haciendo_boost = false
	var destino := position
	if rebote_x:
		destino.x = CENTRO_RING.x
	if rebote_y:
		destino.y = CENTRO_RING.y

	var tween := create_tween()
	tween.tween_property(self, "position", destino, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	rebotando = false

func _comprobar_doble_toque(tecla: int, dir: Vector2) -> void:
	var pulsada_ahora = Input.is_physical_key_pressed(tecla)
	if pulsada_ahora and not estado_teclas_mov[tecla]:
		if ultima_tecla == tecla and tiempo_desde_ultimo_toque > 0.0 and tiempo_recarga_boost <= 0.0 and not haciendo_boost:
			activar_boost(dir)
			ultima_tecla = -1
		else:
			ultima_tecla = tecla
			tiempo_desde_ultimo_toque = 0.25
	estado_teclas_mov[tecla] = pulsada_ahora

func activar_boost(dir: Vector2) -> void:
	haciendo_boost = true
	direccion_boost = dir
	tiempo_recarga_boost = cooldown_boost
	boost_cambiado.emit(0.0, cooldown_boost)

	await get_tree().create_timer(duracion_boost).timeout
	haciendo_boost = false

func golpear():
	atacando = true
	position.x -= 15
	
	var areas_tocadas = hitbox_puno.get_overlapping_areas()
	for area in areas_tocadas:
		if area.name == "Hurtbox" and area.get_parent() != self:
			var rival = area.get_parent()
			rival.vida = max(0, rival.vida - Dano)
			rival.vida_cambiada.emit(rival.vida)
			break

	await get_tree().create_timer(0.12).timeout
	position.x += 15
	
	await get_tree().create_timer(0.2).timeout
	atacando = false
