extends "res://Characters/Gura/GuraBase.gd"

const STYLE = 0

# Steps to add an attack:
# 1. Add it in MOVE_DATABASE
# 2. Add it in state_detect()
# 3. Add it in _on_SpritePlayer_anim_finished() to set the transitions
# 4. Add it in _on_SpritePlayer_anim_started() to set up sfx_over, entity/sfx spawning  and other physics modifying characteristics
# 5. Add it in process_buffered_input() for inputs
# 6. Add it in capture_combinations() if it is a special action

# --------------------------------------------------------------------------------------------------

# shortening code, set by main character node
onready var Character = get_parent()
var Animator
var sprite

func _ready():
	get_node("TestSprite").hide() # test sprite is for sizing collision box
	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main character node
	match anim:
		
		"AirDashU2", "AirDashD2":
			return Globals.char_state.AIR_RECOVERY
		
		"L1Startup", "L2Startup", "F1Startup", "F2Startup", "F2bStartup", "F3Startup", "HStartup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"L1Active", "L1bActive", "L2Active", "F1Active", "F2Active", "F3Active", "HActive", "HbActive":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"L1Recovery", "L1bRecovery", "L2bRecovery", "F1Recovery", "F2Recovery", "F3Recovery", "HRecovery":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"L1bCRecovery", "F1CRecovery":
			return Globals.char_state.GROUND_C_RECOVERY
			
		"aL1Startup", "aL2Startup", "aF1Startup", "aF3Startup", "aHStartup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aL1Active", "aL2Active", "aF1Active", "aF3Active", "aHActive":
			return Globals.char_state.AIR_ATK_ACTIVE
		"L2Recovery", "aL1Recovery", "aL2Recovery", "aL2bRecovery", "aF1Recovery", "aF3Recovery", "aHRecovery":
			return Globals.char_state.AIR_ATK_RECOVERY
		"L2cCRecovery", "aF1CRecovery", "aF3CRecovery":
			return Globals.char_state.AIR_C_RECOVERY
			
			
func check_collidable(): # some characters have move that can pass through other characters
	match Animator.to_play_animation:
#		"Dash": 			# example
#			return false
		_:
			pass
	return true
			
	
# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the character
	
func stimulate():
	
#	Character.input_state
#	Character.dir
#	Character.v_dir
	
	# WIP, air strafing during aL2
	# releasing Light during aL2
	
	if Character.state == Globals.char_state.AIR_ATK_ACTIVE and Animator.query(["aL2Active"]):
		if Character.grounded:
			Character.animate("HardLanding")
		elif !Character.button_light in Character.input_state.pressed:
			Character.animate("aL2bRecovery")
	
	# QUICK CANCELS --------------------------------------------------------------------------------------------------
	
	if Character.check_quick_cancel():
		
		if Character.button_up in Character.input_state.just_pressed:
			if Animator.query(["F1Startup"]) and Character.test_qc_chain_combo("F3"):
				Character.animate("F3Startup")
			elif Animator.query(["aF1Startup"]) and Character.test_qc_chain_combo("aF3"):
				Character.animate("aF3Startup")
				
		if Character.button_up in Character.input_state.just_released:
			if Animator.query(["F3Startup"]) and Character.test_qc_chain_combo("F1"):
				Character.animate("F1Startup")
			elif Animator.query(["aF3Startup"]) and Character.test_qc_chain_combo("aF1"):
				Character.animate("aF1Startup")
				
		if Character.button_down in Character.input_state.just_pressed:
			if Animator.query(["F1Startup"]) and Character.test_qc_chain_combo("F2"):
				Character.animate("F2Startup")
			elif Animator.query(["L1Startup"]) and Character.test_qc_chain_combo("L2"):
				Character.animate("L2Startup")
			elif Animator.query(["aL1Startup"]) and Character.test_qc_chain_combo("aL2"):
				Character.animate("aL2Startup")
				
		if Character.button_down in Character.input_state.just_released:
			if Animator.query(["F2Startup"]) and Character.test_qc_chain_combo("F1"):
				Character.animate("F1Startup")
			elif Animator.query(["L2Startup"]) and Character.test_qc_chain_combo("L1"):
				Character.animate("L1Startup")
			elif Animator.query(["aL2Startup"]) and Character.test_qc_chain_combo("aL1"):
				Character.animate("aL1Startup")				
				
		if Character.button_fierce in Character.input_state.just_pressed:
			if Animator.query(["L1Startup", "L2Startup"]) and Character.test_qc_chain_combo("H"):
				Character.animate("HStartup")
			elif Animator.query(["aL1Startup", "aL2Startup"]) and Character.test_qc_chain_combo("aH"):
				Character.animate("aHStartup")
		
		if Character.button_light in Character.input_state.just_pressed:
			if Animator.query(["F1Startup", "F2Startup", "F3Startup"]) and Character.test_qc_chain_combo("H"):
				Character.animate("HStartup")
			elif Animator.query(["aF1Startup", "aF3Startup"]) and Character.test_qc_chain_combo("aH"):
				Character.animate("aHStartup")

# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------


func capture_combinations():
	
	Character.combination(Character.button_up, Character.button_fierce, "UpFierce") # can quick_cancel from light/fierce startup	
	
	# Heavy Normal, place this after UpFierce
	Character.combination(Character.button_light, Character.button_fierce, "H") # can quick_cancel from light/fierce startup

	# Command Normals

	if Character.get_node("SpecialTimer").is_running():
		# insert Specials here
		# also have InstaJumpAct Specials
		pass
	elif Character.get_node("EXTimer").is_running():
		# insert EX Moves here
		# also have InstaJumpAct EX Moves
		pass
	elif Character.get_node("SuperTimer").is_running():
		# insert Supers here
		# also have InstaJumpAct Supers
		pass


# INPUT BUFFER --------------------------------------------------------------------------------------------------

# called by main character node
func process_buffered_input(new_state, buffered_input, input_to_add, has_acted: Array):
	var keep = true
	match buffered_input[0]:
		
		Character.button_dash:
			match new_state:
				
			# GROUND DASH ---------------------------------------------------------------------------------
		
				Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
					if keep and !Animator.query(["DashBrake"]): # cannot dash during dash brake
						Character.animate("DashTransit")
						keep = false
						
			# AIR DASH ---------------------------------------------------------------------------------
				
				Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
					if Character.air_dash > 0:
						if Character.button_down in Character.input_state.pressed and Character.check_snap_up():
							
							if Character.velocity_previous_frame.y < 0: # moving upward
								Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox"))
								if Character.dir != 0:
#									Character.face(Character.dir)
									Character.animate("AirDashD") # snap up waveland if going upward, landing check will change it to brake later
								else:
									Character.animate("AirDashDD") 
							elif Animator.time == 0: # moving downward and within 1st frame of falling, for easy wavedashing on soft platforms
								Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox"))
								Character.animate("JumpTransit") # if snapping up while falling downward, instantly wavedash
								input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
								
							else: # moving downward and in place of snap up but too late
								Character.animate("AirDashTransit") # for dropping down and air dashing ASAP
						else:
							Character.animate("AirDashTransit")
						keep = false
						
				Globals.char_state.AIR_STARTUP: # cancel start of air jump into air dash
					if Animator.query(["AirJumpTransit", "WallJumpTransit", "AirJumpTransit2", "WallJumpTransit2"]):
						if Character.air_dash > 0:
							Character.animate("AirDashTransit")
							keep = false
							
			# DASH CANCELS ---------------------------------------------------------------------------------
				# if land a sweetspot hit, can dash cancel afterward
							
				Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.GROUND_ATK_ACTIVE:
					if Character.dash_cancel:
						Character.animate("DashTransit")
						keep = false
						
				Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_ATK_ACTIVE:
					if Character.dash_cancel:
						if !Character.grounded:
							if Character.air_dash > 0:
								Character.animate("AirDashTransit")
								keep = false
						else: # grounded
							Character.animate("DashTransit")
							keep = false
		
		# ---------------------------------------------------------------------------------
		
		Character.button_light:
			if !has_acted[0]:
				if Character.button_down in Character.input_state.pressed:
					keep = !process_button(new_state, "L2", has_acted, buffered_input[1])
				if keep:
					keep = !process_button(new_state, "L1", has_acted, buffered_input[1])
		
		Character.button_fierce:
			if !has_acted[0]:
				if Character.button_up in Character.input_state.pressed:
					keep = !process_button(new_state, "F3", has_acted, buffered_input[1]) # need to do this too for more consistency
				elif Character.button_down in Character.input_state.pressed:
					keep = !process_button(new_state, "F2", has_acted, buffered_input[1])
				if keep:
					keep = !process_button(new_state, "F1", has_acted, buffered_input[1])


		# SPECIAL ACTIONS ---------------------------------------------------------------------------------
		# buffered_input_action can be a string instead of int, for heavy attacks and special moves

		"UpFierce":
			if !has_acted[0]:
				keep = !process_button(new_state, "F3", has_acted, buffered_input[1])
				
		"H":
			if !has_acted[0]:
				keep = !process_button(new_state, "H", has_acted, buffered_input[1])
		
		"InstaAirDash":
			match new_state:
				Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
					Character.animate("JumpTransit")
					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
					has_acted[0] = true
					keep = false
				Globals.char_state.GROUND_STARTUP:
					Character.animate("JumpTransit")
					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
					has_acted[0] = true
					keep = false
	
	# ---------------------------------------------------------------------------------
	
	return keep # return true to keep buffered_input, false to remove buffered_input
	# no need to return input_to_add since array is passed by reference


func process_button(new_state, attack_ref: String, has_acted: Array, buffer_time): # return true if button consumed
	match new_state:
			
			Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
				if attack_ref in MOVE_DATABASE:
					Character.animate(attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
				
			Globals.char_state.GROUND_STARTUP:
				if Character.button_up in Character.input_state.pressed and !Character.button_jump in Character.input_state.pressed and \
						Animator.query(["JumpTransit"]):
					 # can cancel JumpTransit into any up-tilts, unless holding jump
					if attack_ref in MOVE_DATABASE:
						Character.animate(attack_ref + "Startup")
						Character.chain_memory = []
						has_acted[0] = true
						return true
						
			Globals.char_state.AIR_STARTUP:
				if Character.button_up in Character.input_state.pressed and !Character.button_jump in Character.input_state.pressed and \
						Animator.query(["AirJumpTransit"]):
					 # can cancel AirJumpTransit into any up-tilts, unless holding jump
					if "a" + attack_ref in MOVE_DATABASE and !("a" + attack_ref in Character.aerial_memory):
						Character.animate("a" + attack_ref + "Startup")
						Character.chain_memory = []
						has_acted[0] = true
						return true
				
			Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
				if !Character.grounded: # must be currently not grounded even if next state is still considered an aerial state
					if "a" + attack_ref in MOVE_DATABASE and !("a" + attack_ref in Character.aerial_memory):
						Character.animate("a" + attack_ref + "Startup")
						Character.chain_memory = []
						has_acted[0] = true
						return true
				
			Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.GROUND_ATK_ACTIVE:
				if attack_ref in MOVE_DATABASE:
					if Character.test_chain_combo(attack_ref):
						if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
							Character.get_node("ModulatePlayer").play("unflinch_flash")
							Character.perfect_chain = true
						Character.animate(attack_ref + "Startup")
						has_acted[0] = true
						return true
					
			Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_ATK_ACTIVE:
				if !Character.grounded:
					if "a" + attack_ref in MOVE_DATABASE and !("a" + attack_ref in Character.aerial_memory):
						if Character.test_chain_combo("a" + attack_ref):
							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
								Character.get_node("ModulatePlayer").play("unflinch_flash")
								Character.perfect_chain = true
							Character.animate("a" + attack_ref + "Startup")
							has_acted[0] = true
							return true
				else:
					if attack_ref in MOVE_DATABASE:
						if Character.test_chain_combo(attack_ref): # grounded
							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
								Character.get_node("ModulatePlayer").play("unflinch_flash")
								Character.perfect_chain = true
							Character.animate(attack_ref + "Startup")
							has_acted[0] = true
							return true
					
	return false
						
# ---------------------------------------------------------------------------------
	
#func hop(): # done by pressing down when jumping, can be different for various characters
#	Character.velocity.y = -JUMP_SPEED * 0.9
#	Character.emit_signal("SFX","JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
	
func consume_one_air_dash(): # different characters can have different types of air_dash consumption
	Character.air_dash -= 1
	
func gain_one_air_dash(): # different characters can have different types of air_dash consumption
	if Character.air_dash < Character.max_air_dash: # cannot go over
		Character.air_dash += 1

func shadow_trail():# process shadow trail
	# Character.shadow_trail() can accept 2 parameters, 1st is the starting modulate, 2nd is the lifetime
	
	# shadow trail for certain modulate animations with the key "shadow_trail"
	if LoadedSFX.modulate_animations.has(Character.get_node("ModulatePlayer").current_animation) and \
			LoadedSFX.modulate_animations[Character.get_node("ModulatePlayer").current_animation].has("shadow_trail") and \
			Character.get_node("ModulatePlayer").is_playing():
		# basic shadow trail for "shadow_trail" = 0
		if LoadedSFX.modulate_animations[Character.get_node("ModulatePlayer").current_animation]["shadow_trail"] == 0:
			Character.shadow_trail()
			return
			
	match Animator.to_play_animation:
		"Dash", "AirDash", "AirDashD", "AirDashU", "AirDashUU", "AirDashDD":
			Character.shadow_trail()


func query_move_data(move_name):
	# move data may change for certain moves under certain conditions, unique to character
	var move_data = MOVE_DATABASE[move_name]
	
	match move_data:
		_ :
			pass
	
	return move_data
	

func landed_a_hit(_hit_data): # reaction, can change hit_data from here
	if Animator.query(["aL2Active"]):
		Character.animate("aL2Recovery")
	elif Animator.query(["L2Active"]):
		Character.animate("L2Recovery")
	
	
func being_hit(hit_data): # reaction, can change hit_data from here
	var defender = get_node(hit_data.defender_nodepath)
	
	if !hit_data.weak_hit and hit_data.move_data.damage > 0:
		match defender.state:
			Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_RECOVERY:
				if Animator.query(["AirDashU2", "AirDashD2"]):
					hit_data.punish_hit = true
					
	
func query_traits(): # may have special conditions
	return TRAITS

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"DashTransit":
			Character.animate("Dash")
		"Dash":
			Character.animate("DashBrake")
		"DashBrake":
			Character.animate("Idle")
		"AirDashTransit":
			if Character.air_dash > 1:
				if Character.button_down in Character.input_state.pressed and Character.dir != 0: # downward air dash
#					Character.face(Character.dir)
					Character.animate("AirDashD")
				elif Character.button_up in Character.input_state.pressed and Character.dir != 0: # upward air dash
#					Character.face(Character.dir)
					Character.animate("AirDashU")
				elif Character.button_down in Character.input_state.pressed: # downward air dash
					Character.animate("AirDashDD")
				elif Character.button_up in Character.input_state.pressed: # upward air dash
					Character.animate("AirDashUU")
				else: # horizontal air dash
					Character.animate("AirDash")
			else:
				if Character.button_down in Character.input_state.pressed: # downward air dash
					Character.animate("AirDashD2")
				elif Character.button_up in Character.input_state.pressed: # upward air dash
					Character.animate("AirDashU2")
				else: # horizontal air dash
					Character.animate("AirDash")	
		"AirDash", "AirDashD", "AirDashU", "AirDashUU", "AirDashDD", "AirDashD2", "AirDashU2":
			Character.animate("AirDashBrake")
		"AirDashBrake":
			Character.animate("Fall")
			
		"L1Startup":
			Character.animate("L1Active")
			Character.atk_startup_resets() # need to do this here to work
		"L1Active":
			Character.animate("L1Recovery")
		"L1Recovery":
			Character.animate("L1bActive")
			Character.atk_startup_resets()
		"L1bActive":
			Character.animate("L1bRecovery")
		"L1bRecovery":
			Character.animate("L1bCRecovery")
		"L1bCRecovery":
			Character.animate("Idle")
			
		"L2Startup":
			Character.animate("L2Active")
			Character.atk_startup_resets() # need to do this here to work
		"L2Active":
			if Character.grounded:
				Character.animate("L2bRecovery")
			else:
				Character.animate("L2cCRecovery")
		"L2Recovery":
			Character.animate("FallTransit")
		"L2bRecovery":
			Character.animate("Idle")
		"L2cCRecovery":
			Character.animate("FallTransit")
			
		"F1Startup":
			Character.animate("F1Active")
			Character.atk_startup_resets() # need to do this here to work
		"F1Active":
			Character.animate("F1Recovery")
		"F1Recovery":
			Character.animate("F1CRecovery")
		"F1CRecovery":
			Character.animate("Idle")
			
		"F2Startup":
			Character.animate("F2bStartup")
		"F2bStartup":
			Character.animate("F2Active")
			Character.atk_startup_resets()
		"F2Active":
			Character.animate("F2Recovery")
		"F2Recovery":
			Character.animate("Idle")
			
		"F3Startup":
			Character.animate("F3Active")
			Character.atk_startup_resets()
		"F3Active":
			Character.animate("F3Recovery")
		"F3Recovery":
			Character.animate("Idle")

		"HStartup":
			Character.animate("HActive")
			Character.atk_startup_resets()
		"HActive":
			Character.animate("HbActive")
			Character.atk_startup_resets()
		"HbActive":
			Character.animate("HRecovery")	
		"HRecovery":
			Character.animate("Idle")

		"aL1Startup":
			Character.animate("aL1Active")
			Character.atk_startup_resets()
		"aL1Active":
			Character.animate("aL1Recovery")
		"aL1Recovery":
			Character.animate("FallTransit")

		"aL2Startup":
			Character.animate("aL2Active")
			Character.atk_startup_resets()
		"aL2Recovery":
			if Character.button_light in Character.input_state.pressed:
				Character.animate("aL2Startup")
			else:
				Character.animate("aL2bRecovery")
		"aL2bRecovery":
			Character.animate("FallTransit")

		"aF1Startup":
			Character.animate("aF1Active")
			Character.atk_startup_resets()
		"aF1Active":
			Character.animate("aF1Recovery")
		"aF1Recovery":
			Character.animate("aF1CRecovery")
		"aF1CRecovery":
			Character.animate("FallTransit")

		"aF3Startup":
			Character.animate("aF3Active")
			Character.atk_startup_resets()
		"aF3Active":
			Character.animate("aF3Recovery")
		"aF3Recovery":
			Character.animate("aF3CRecovery")
		"aF3CRecovery":
			Character.animate("FallTransit")
	
		"aHStartup":
			Character.animate("aHActive")
			Character.atk_startup_resets()
		"aHActive":
			Character.animate("aHRecovery")
		"aHRecovery":
			Character.animate("FallTransit")

func _on_SpritePlayer_anim_started(anim_name):
		
	if Character.is_atk_active():
		var move_name = anim_name.trim_suffix("Active")
		if move_name in MOVE_DATABASE:
			Character.chain_memory.append(move_name)
		
	match anim_name:
		"Dash":
			Character.velocity.x = GROUND_DASH_SPEED * Character.facing
			Character.null_friction = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true})	
		"AirDashTransit":
			Character.aerial_memory = []
			Character.velocity.x *= 0.2
			Character.velocity.y *= 0.2
			Character.null_gravity = true
		"AirDash":
			consume_one_air_dash()
			if Character.air_dash == 0:
				Character.velocity.x = AIR_DASH_SPEED * 1.3 * Character.facing
			else:
				Character.velocity.x = AIR_DASH_SPEED * Character.facing
			Character.velocity.y = 0
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing})
		"AirDashD":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/4 * Character.facing)
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/4})
		"AirDashU":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/4 * Character.facing)
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/4})	
		"AirDashDD":
			consume_one_air_dash()
#			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/2 * Character.facing)
			Character.velocity.y = AIR_DASH_SPEED
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/2})
		"AirDashUU":
			consume_one_air_dash()
#			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/2 * Character.facing)
			Character.velocity.y = -AIR_DASH_SPEED
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/2})	
		"AirDashD2":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * 1.3 * Character.facing, 0).rotated(PI/8 * Character.facing)
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/8})
		"AirDashU2":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * 1.3 * Character.facing, 0).rotated(-PI/8 * Character.facing)
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/8})	
			
		"L2Startup":
			Character.velocity.x += Character.facing * SPEED * 0.8
		"L2Active":
			Character.velocity.x += Character.facing * SPEED * 1.2
			Character.null_friction = true
			Character.emit_signal("SFX", "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true})
		"L2Recovery":
			Character.velocity = Vector2(500 * Character.facing, 0).rotated(-PI/2.3 * Character.facing)
		"F1Startup":
			Character.velocity.x += Character.facing * SPEED * 0.25
		"F1Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			Character.emit_signal("SFX", "RunDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Character.sfx_over.show()
		"F2bStartup":
			Character.velocity.x += Character.facing * SPEED * 0.5
			Character.emit_signal("SFX", "RunDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"F1Recovery", "F2Active", "F2Recovery", "F3Active", "F3Recovery":
			Character.sfx_over.show()
		"HStartup":
			Character.velocity.x += Character.facing * SPEED * 0.5
			Character.emit_signal("SFX", "RunDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"HActive", "HbActive", "HRecovery":
			Character.sfx_under.show()
			
		"aL1Startup","aL1Active", "aL1Recovery":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.2
			Character.sfx_under.show()
		"aL2Startup", "aL2Active":
			Character.velocity_limiter.x = 0.75
			Character.velocity_limiter.down = 1.2
		"aL2Recovery":
			Character.velocity.y = -600
			Character.sfx_over.show()
		"aF1Startup", "aF1Active", "aF1Recovery":
			Character.velocity_limiter.x = 0.75
			Character.velocity_limiter.down = 1.0
			Character.sfx_over.show()
		"aF3Startup":
			Character.velocity = Vector2(400 * Character.facing, 0).rotated(-PI/2.5 * Character.facing)
			Character.null_gravity = true
		"aF3Active":
			Character.velocity *= 0.5
			Character.null_gravity = true
			Character.sfx_over.show()
		"aF3Recovery":
			Character.velocity_limiter.x = 0.75
			Character.velocity_limiter.down = 1.0
			Character.sfx_over.show()
		"aHStartup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.null_gravity = true
			Character.sfx_over.show()
		"aHActive":
			Character.velocity = Vector2.ZERO
			Character.velocity_limiter.x = 0
			Character.null_gravity = true
			Character.sfx_over.show()
		"aHRecovery":
			Character.velocity_limiter.x = 0.7
			Character.velocity_limiter.down = 0.7
			Character.sfx_over.show()
		

	start_audio(anim_name)


func start_audio(anim_name):
	
	if Character.is_atk_active():
		var move_name = anim_name.trim_suffix("Active")
		if move_name in MOVE_DATABASE:
			if "move_sound" in MOVE_DATABASE[move_name]:
				if !MOVE_DATABASE[move_name].move_sound is Array:
					Character.play_audio(MOVE_DATABASE[move_name].move_sound.ref, MOVE_DATABASE[move_name].move_sound.aux_data)
				else:
					for sound in MOVE_DATABASE[move_name].move_sound:
						Character.play_audio(sound.ref, sound.aux_data)
	
	match anim_name:
		"JumpTransit2", "WallJumpTransit2", "BlockHopTransit2":
			Character.play_audio("jump1", {"bus":"PitchDown"})
		"AirJumpTransit2":
			Character.play_audio("jump1", {"vol":-2})
		"SoftLanding", "HardLanding", "BlockLanding":
			Character.play_audio("land1", {})
		"LaunchTransit":
			if Character.grounded and abs(Character.velocity.y) < 1:
				Character.play_audio("launch2", {"vol" : -3, "bus":"LowPass"})
			else:
				Character.play_audio("launch1", {"vol":-15, "bus":"PitchDown"})
		"Dash":
			Character.play_audio("dash1", {"vol" : -6, "bus":"PitchDown2"})
		"AirDash", "AirDashD", "AirDashU", "AirDashDD", "AirDashUU", "AirDashD2", "AirDashU2":
			Character.play_audio("dash1", {"vol" : -6})
			
		"BurstCounterStartup", "BurstEscapeStartup":
			Character.play_audio("faller1", {"vol" : -12,})
		"BurstCounter", "BurstEscape":
			Character.play_audio("blast1", {"vol" : -18,})


func stagger_audio():
	# WIP, for animations like Run to produce footsteps during certain frames
	
	match Animator.current_animation:
		"Run":
			match sprite.frame:
				38, 41:
					Character.play_audio("footstep2", {"vol":-1})



