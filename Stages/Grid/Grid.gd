extends "res://Scenes/Stage/Stage.gd"

const NAME = "Grid"

const MUSIC = [{
		"name" : "Survival Theme",
		"artist" : "Zortoise",
		"audio" : "res://Assets/Music/Survival1.ogg",
		"loop_start": 0.098,
		"loop_end": 157.206,
		"vol" : -4,
	}]

func _ready():
	if Globals.survival_level != null:
		$SoftPlatform1.free()
		$SoftPlatform2.free()
		$MPlatform1.free()
		$MPlatform2.free()
		
	elif Globals.static_stage != 0:
		$MPlatform2.free()
