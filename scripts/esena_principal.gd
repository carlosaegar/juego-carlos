extends Node2D

@onready var round1 = $Round1
@onready var boxeador1 = $boxeador1
@onready var boxeador2 = $boxeador2

func _ready() -> void:
	# los dos boxeadores escondidos
	boxeador1.hide()
	boxeador2.hide()
	boxeador1.set_process(false)
	boxeador2.set_process(false)

	# Cuando el señor con el cartel termine su vuelta 
	#se muestran los dos personajes
	round1.vuelta_terminada.connect(_on_vuelta_terminada)

func _on_vuelta_terminada() -> void:
	boxeador1.show()
	boxeador2.show()
	boxeador1.set_process(true)
	boxeador2.set_process(true)
