extends Sprite2D

@export var velocidad: float = 200.0

func _process(delta: float) -> void:
	var direccionx := Input.get_axis("izquierda_pl2", "derecha_pl2")
	var direcciony := Input.get_axis("arriba_pl2", "abajo_pl2")
	position.x += direccionx * velocidad * delta
	position.y += direcciony * velocidad * delta
