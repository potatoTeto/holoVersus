extends Node2D

var master_node = null # not saved, set when loading state
var player_image := false # not saved, afterimage is that of a player

var free := false

var life # current
var lifetime
var color_modulate
var starting_modulate_a

var master_ID: int
var spritesheet_ref: String
var afterimage_shader = Globals.afterimage_shader.MASTER
var ignore_freeze := false
var mob_ref = null
var mob_palette_ref = null

func init(in_master_ID: int, in_spritesheet_ref: String, sprite_node_path: NodePath, in_color_modulate = null, \
		in_starting_modulate_a = 0.5, in_lifetime = 10.0, in_afterimage_shader = Globals.afterimage_shader.MASTER, \
		in_mob_ref = null, in_mob_palette_ref = null):
	
	master_ID = in_master_ID
	spritesheet_ref = in_spritesheet_ref
	mob_ref = in_mob_ref
	mob_palette_ref = in_mob_palette_ref
	
	set_texture()

	afterimage_shader = in_afterimage_shader
	apply_shader()

	var sprite_base = get_node(sprite_node_path)
	$Sprite.hframes = sprite_base.hframes
	$Sprite.vframes = sprite_base.vframes
	$Sprite.frame = sprite_base.frame
	$Sprite.scale = sprite_base.scale
	$Sprite.rotation = sprite_base.rotation
	
	color_modulate = in_color_modulate
	if color_modulate != null:
		$Sprite.modulate.r = color_modulate.r
		$Sprite.modulate.g = color_modulate.g
		$Sprite.modulate.b = color_modulate.b
	
	life = in_lifetime
	lifetime = in_lifetime
	starting_modulate_a = float(in_starting_modulate_a)
	$Sprite.modulate.a = starting_modulate_a
	position = sprite_base.global_position
	
	if Globals.Game.is_stage_paused(): # if spawned during screenfreeze, will not be frozen during screenfreeze
		ignore_freeze = true
		
func set_texture():
	if mob_ref == null:
		master_node = Globals.Game.get_player_node(master_ID)
		if spritesheet_ref in master_node.spritesheets:
			$Sprite.texture = master_node.spritesheets[spritesheet_ref]
			player_image = true
		elif spritesheet_ref in master_node.entity_data: # entity ref passed in instead
			$Sprite.texture = master_node.entity_data[spritesheet_ref].spritesheet
		else:
			print("Error: " + spritesheet_ref + " spritesheet not found in Afterimage.gd.")
	else:
		if spritesheet_ref in Globals.Game.LevelControl.mob_data[mob_ref].spritesheets:
			$Sprite.texture = Globals.Game.LevelControl.mob_data[mob_ref].spritesheets[spritesheet_ref]
			player_image = true
		elif spritesheet_ref in Globals.Game.LevelControl.mob_data[mob_ref].entity_data: # entity ref passed in instead
			$Sprite.texture = Globals.Game.LevelControl.mob_data[mob_ref].entity_data[spritesheet_ref].spritesheet
		else:
			print("Error: " + spritesheet_ref + " spritesheet not found in Afterimage.gd.")
			

func apply_shader():
	match afterimage_shader:
		Globals.afterimage_shader.NONE:
			pass
		Globals.afterimage_shader.MASTER:
			if mob_ref != null:
				if mob_palette_ref != null:
					$Sprite.material = ShaderMaterial.new()
					$Sprite.material.shader = Globals.loaded_palette_shader
					$Sprite.material.set_shader_param("swap", Globals.Game.LevelControl.mob_data[mob_ref].palettes[mob_palette_ref])
			elif master_node.loaded_palette != null:
				$Sprite.material = ShaderMaterial.new()
				$Sprite.material.shader = Globals.loaded_palette_shader
				$Sprite.material.set_shader_param("swap", master_node.loaded_palette)
		Globals.afterimage_shader.MONOCHROME:
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Globals.monochrome_shader
		Globals.afterimage_shader.WHITE:
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Globals.white_shader
			$Sprite.material.set_shader_param("whitening", 1.0)

func simulate():
	if Globals.Game.is_stage_paused() and !ignore_freeze: return
	
	if player_image:
		master_node = Globals.Game.get_player_node(master_ID)
		if master_node != null and master_node.get_node("HitStopTimer").is_running() and !master_node.get_node("HitStunTimer").is_running():
			return # does not advance if afterimage owner is a player and is in attacker hitstop
	
	life -= 1.0
	$Sprite.modulate.a = lerp(starting_modulate_a, 0.0, 1.0 - float(life)/lifetime)
	
	if life <= 0.0:
		free = true # don't use queue_free!


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"master_ID" : master_ID,
		"spritesheet_ref" : spritesheet_ref,
		"mob_ref" : mob_ref,
		"mob_palette_ref" : mob_palette_ref,
		"afterimage_shader" : afterimage_shader,
		"hframes" : $Sprite.hframes,
		"vframes" : $Sprite.vframes,
		"frame" : $Sprite.frame,
		"scale" : $Sprite.scale,
		"rotation" : $Sprite.rotation,
		"color_modulate" : color_modulate,
		
		"life" : life,
		"lifetime" : lifetime,
		"starting_modulate_a" : starting_modulate_a,
		"free" : free,
		"position" : position,
		"ignore_freeze" : ignore_freeze
	}
	return state_data
	
func load_state(state_data):
	
	master_ID = state_data.master_ID
	master_node = Globals.Game.get_player_node(master_ID)
	spritesheet_ref = state_data.spritesheet_ref
	mob_ref = state_data.mob_ref
	mob_palette_ref = state_data.mob_palette_ref
	
	set_texture()
	
	afterimage_shader = state_data.afterimage_shader
	apply_shader()
	
	$Sprite.hframes = state_data.hframes
	$Sprite.vframes = state_data.vframes
	$Sprite.frame = state_data.frame
	$Sprite.scale = state_data.scale
	$Sprite.rotation = state_data.rotation
	
	color_modulate = state_data.color_modulate
	if color_modulate != null:
		$Sprite.modulate.r = color_modulate.r
		$Sprite.modulate.g = color_modulate.g
		$Sprite.modulate.b = color_modulate.b

	life = state_data.life
	lifetime = state_data.lifetime
	starting_modulate_a = state_data.starting_modulate_a
	free = state_data.free
	position = state_data.position

	$Sprite.modulate.a = lerp(starting_modulate_a, 0.0, 1.0 - life/lifetime)
	ignore_freeze = state_data.ignore_freeze
	
#--------------------------------------------------------------------------------------------------
