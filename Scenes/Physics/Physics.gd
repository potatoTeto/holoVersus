extends Node2D
# let every moveable object extend this script


# soft_platform_dbox is needed to phase through soft platforms
func move(collision_box, soft_platform_dbox, ledge_stop = false): # uses the object's velocity
	
	if get("velocity").x == 0 and get("velocity").y == 0: return [false, false, false]
	
	var checklist: Array = create_checklist()
	
	call("move_true_position", get("velocity")) # first, move the true position
	var target_position: Vector2 = call("get_rounded_position")  # then get the new target position derived from the true position
	
	var move_amount = Vector2.ZERO # get the number of pixels to move horziontally/vertically from target position - current position
	move_amount.x = target_position.x - position.x
	move_amount.y = target_position.y - position.y
	
	# quick check
	var test_rect := Rect2(collision_box.rect_global_position, collision_box.rect_size)
	var test_rect2 := Rect2(soft_platform_dbox.rect_global_position, soft_platform_dbox.rect_size)
	test_rect.position.x += move_amount.x
	test_rect.position.y += move_amount.y
	test_rect2.position.x += move_amount.x
	test_rect2.position.y += move_amount.y
	if check_test_rect(test_rect, test_rect2, checklist, ledge_stop):
		position = target_position
		return [false, false, false]
	
	var results = move_amount(move_amount, collision_box, soft_platform_dbox, checklist, ledge_stop, false) # move and change the velocity as needed
	
	if position != target_position: # unable to reach target_position (collision, pushing, etc), set true position to current position
		call("set_true_position")
	
	return results # [landing_check, collision_check, ledgedrop_check]
	
func move_amount(move_amount:Vector2, collision_box, soft_platform_dbox, checklist: Array, ledge_stop = false, manual_move = false):
	# will only collide with other players if owner of collision_box is a player
	# just in case...
	move_amount.x = int(move_amount.x)
	move_amount.y = int(move_amount.y)
	
	var landing_check := false
	var collision_check := false
	var ledgedrop_check := false
	
	while move_amount.x != 0:
		if ledge_stop and is_against_ledge(soft_platform_dbox, sign(move_amount.x)): # if ledge_stop is true, ledges will stop movement
			if !manual_move:
				get("velocity").x = 0
			ledgedrop_check = true
			break
		# velocity.x can be stopped by walls and players (for characters)
		elif !is_against_wall(collision_box, soft_platform_dbox, sign(move_amount.x), checklist):
			
			# for players, has to test collision with other players as well
			if collision_box.is_in_group("Players") or collision_box.is_in_group("Mobs"):
				
				var colliding_characters = get_colliding_characters_side(collision_box, checklist, sign(move_amount.x))
				if colliding_characters.size() == 0: # no collision with other players
					position.x += sign(move_amount.x)
					move_amount.x -= sign(move_amount.x)
				else:
					for colliding_character in colliding_characters: # push collided player 1 pixel while you lose 1 move_amount
						if colliding_character.has_node("SoftPlatformDBox"):
							colliding_character.move_amount(Vector2(sign(move_amount.x), 0), colliding_character.get_node("PlayerCollisionBox"), \
								colliding_character.get_node("SoftPlatformDBox"), colliding_character.create_checklist())
						else:
							colliding_character.move_amount(Vector2(sign(move_amount.x), 0), colliding_character.get_node("PlayerCollisionBox"), \
								colliding_character.get_node("PlayerCollisionBox"), colliding_character.create_checklist())
						colliding_character.set_true_position()
						
					move_amount.x -= sign(move_amount.x) # skip moving this move_amount
					if !manual_move:
						get("velocity").x = FMath.percent(get("velocity").x, get("PLAYER_PUSH_SLOWDOWN")) # slow you down a little more
						
			else: # non-player moving
				position.x += sign(move_amount.x)		
				move_amount.x -= sign(move_amount.x)
			if not_in_sequence(collision_box) and check_offstage(collision_box): # ringed out
				return [false, false, false]
		else: # hit a wall
			if !manual_move:
				get("velocity").x = 0
			collision_check = true
			break
			
	while move_amount.y != 0:
		# velocity.y is stopped by floors and may be stopped by soft floors
		if move_amount.y < 0: # moving upwards
			# if no solid platform above
			if !is_against_ceiling(collision_box, soft_platform_dbox, checklist):
				position.y += sign(move_amount.y)
				move_amount.y -= sign(move_amount.y)
				
				if not_in_sequence(collision_box) and check_offstage(collision_box):
					return [false, false, false]
					
			else: # hit ceiling
				if !manual_move:
					get("velocity").y = 0
				collision_check = true
				break
		else: # moving downwards
			
			if !is_on_ground(soft_platform_dbox, checklist):
				position.y += sign(move_amount.y)
				move_amount.y -= sign(move_amount.y)
				if check_offstage(collision_box):
					return [false, false, false]
			else: # stop moving
				if !manual_move:
					get("velocity").y = 0
				landing_check = true
				collision_check = true
				break
			
	return [landing_check, collision_check, ledgedrop_check]
	
	
	
func move_sequence_player_to(new_position: Vector2): # called by grabber, also move used to move grabber if grabbed hit a wall
	
	var move_amount := Vector2.ZERO
	move_amount.x = new_position.x - position.x
	move_amount.y = new_position.y - position.y
		
	var results
	if has_node("SoftPlatformDBox"):
		results = move_amount(move_amount, get_node("PlayerCollisionBox"), get_node("SoftPlatformDBox"), create_checklist())
	else:
		results = move_amount(move_amount, get_node("PlayerCollisionBox"), get_node("PlayerCollisionBox"), create_checklist())
	call("set_true_position")
	
	return results # [landing_check, collision_check, ledgedrop_check]
	
	
func move_sequence_player_by(move_amount: Vector2): # in some special cases where move_sequence_player_to() is not enough
	var results
	if has_node("SoftPlatformDBox"):
		results = move_amount(move_amount, get_node("PlayerCollisionBox"), get_node("SoftPlatformDBox"), create_checklist())
	else:
		results = move_amount(move_amount, get_node("PlayerCollisionBox"), get_node("PlayerCollisionBox"), create_checklist())
	
	call("set_true_position")
	return results # [landing_check, collision_check, ledgedrop_check]
	
	
func not_in_sequence(collision_box): # when object is in sequence, will not be killed at ceiling and sides but will die at bottom
	if (collision_box.is_in_group("Players") or collision_box.is_in_group("Mobs")) and \
			get("state") in [Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER]:
		return false
	return true
	
	
func move_no_collision():
	
	if get("velocity").x == 0 and get("velocity").y == 0: return
	
	call("move_true_position", get("velocity")) # first, move the true position
	position = call("get_rounded_position")  # then get the new target position derived from the true position
	
	# check offstage
	if self.is_in_group("PlayerNodes") or self.is_in_group("MobNodes"):
		Globals.Game.detect_kill(get_node("PlayerCollisionBox"))
	elif self.is_in_group("EntityNodes") or self.is_in_group("MobEntityNodes"):
		if has_node("EntitySpriteBox"):
			Globals.Game.detect_offstage(get_node("EntitySpriteBox"))
	
	
func check_offstage(collision_box):
	if collision_box.is_in_group("Players") and Globals.Game.detect_kill(collision_box):
		return true
	elif collision_box.is_in_group("Entities") and collision_box.get_parent().has_node("EntitySpriteBox") and \
			Globals.Game.detect_offstage(collision_box.get_parent().get_node("EntitySpriteBox")):
		# detect_offstage() will handle entities' reaction when becoming offstage
		return true
	return false
	
	
#func check_blast_barriers(collision_box, compass_dir): # return null if not touching barriers, return bounced velocity if so
#	if call("get_damage_percent") >= 100: # no barrier if damage value too high
#		return false
#	match compass_dir:
#		Em.compass.W:
#			if !Detection.detect_duo(collision_box, Globals.Game.blastbarrierL):
#				return null
#			call("bounce_dust", compass_dir)
#			get("velocity").x = -FMath.percent(get("velocity").x, 75)
#			return true
#		Em.compass.E:
#			if !Detection.detect_duo(collision_box, Globals.Game.blastbarrierR):
#				return null
#			call("bounce_dust", compass_dir)
#			get("velocity").x = -FMath.percent(get("velocity").x, 75)
#			return true
#		Em.compass.N:
#			if !Detection.detect_duo(collision_box, Globals.Game.blastbarrierU):
#				return false
#			call("bounce_dust", compass_dir)
#			get("velocity").y = -FMath.percent(get("velocity").y, 25) # bounce down
#			return true
#	return false # just in case

	
# no need to get character collision for up and down movement for now
func get_colliding_characters_side(collision_box, checklist: Array, direction):
	var colliding_characters = []
#	var tester = collision_box.get_parent()
	
	# get an array of character nodes in the way
	var to_check := []
	if "Players" in checklist: to_check.append("Players")
	if "Mobs" in checklist: to_check.append("Mobs")
	if to_check.size() == 0: return []
	
	var characters_detected = Detection.detect_return([collision_box], to_check, Vector2(direction, 0))
	for character in characters_detected:
		if "MOB" in self and "MOB" in character:
			continue # mobs do not collide with each other
		# check if you are moving toward them or away, only collide if moving towards them
		if ((direction == 1 and character.position.x > position.x) or \
				(direction == -1 and character.position.x < position.x)):
			if character.state == Em.char_state.CROUCHING and !get("grounded") and character.position.y > position.y:
				continue # if you are airborne, will not collide with opponents that are crouching and under you
			elif character.has_method("check_collidable") and character.call("check_collidable"): # detected character must be collidable
				colliding_characters.append(character)
			
	return colliding_characters
	
	
func create_checklist() -> Array:
	var to_check := []
	
	if has_method("check_passthrough") and call("check_passthrough"):
		pass
	else:
		to_check.append("SolidPlatforms")
		if has_method("check_fallthrough") and call("check_fallthrough"):
			pass
		else:
			to_check.append("SoftPlatforms")
			
	if is_in_group("PlayerNodes") or is_in_group("ModNodes"):
		to_check.append("BlastWalls")
		to_check.append("BlastCeiling")
		if has_method("is_killable"):
			if call("is_killable", get("velocity").x):
				to_check.erase("BlastWalls")
			if call("is_killable", get("velocity").y):
				to_check.erase("BlastCeiling")
			
		if has_method("check_collidable") and call("check_collidable"):
			to_check.append("Players")
			if is_in_group("ModNodes"): to_check.append("Mobs")
			
		
	if is_in_group("EntityNodes"):
		if Em.entity_trait.BLAST_BARRIER_COLLIDE in get("UniqEntity").TRAITS:
			to_check.append("BlastWalls")
			to_check.append("BlastCeiling")
#		elif get("UniqEntity").has_method("on_offstage"):
#			to_check.erase("BlastBarriers")
			
	return to_check
			
			
	
func check_test_rect(test_rect, test_rect2, checklist: Array, ledge_stop: bool):
	if Detection.detect_bool([test_rect], checklist):
		return false # detected obstacle, failed test
		
	if ledge_stop and !is_on_ground(test_rect2):
		return false # grounded object went off ledge, failed test
		
#	if is_in_group("PlayerNodes"): # player went off stage, failed test
	if Globals.Game.is_offstage(test_rect):
		return false
			
	return true
			
	
# return true if a wall in "direction", 1 is right, -1 is left
func is_against_wall(collision_box, soft_platform_dbox, direction, checklist = null):
			
	var to_check := []
	if checklist == null:
		to_check = ["SolidPlatforms", "BlastWalls"]
	else:
		if "SolidPlatforms" in checklist: to_check.append("BlastWalls")
		if "BlastWalls" in checklist: to_check.append("BlastWalls")
		if to_check.size() == 0: return false
		
	if Detection.detect_bool([collision_box], to_check, Vector2(direction, 0)) and \
			!Detection.detect_bool([soft_platform_dbox], to_check):
		return true
	else:
		return false
		
		
func is_in_wall(soft_platform_dbox):
	
	if has_method("check_passthrough") and call("check_passthrough"):
		return false
	
	if Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms"]):
		return true
	else:
		return false
		
		
func is_against_ledge(soft_platform_dbox, direction):
	if "grounded" in self and !get("grounded"):
		return false
	if !Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms", "SoftPlatforms"], Vector2(direction, 1)):
		return true
	else:
		return false
		
		
func is_against_ceiling(collision_box, soft_platform_dbox, checklist = null): # return true if there is a solid platform above
	
	var to_check := []
	if checklist == null:
		to_check = ["SolidPlatforms", "BlastCeiling"]
	else:
		if "SolidPlatforms" in checklist: to_check.append("SolidPlatforms")
		if "BlastCeiling" in checklist: to_check.append("BlastCeiling")
		if to_check.size() == 0: return false
		
	if Detection.detect_bool([collision_box], to_check, Vector2.UP) and \
			!Detection.detect_bool([soft_platform_dbox], to_check):
#		if collision_box.is_in_group("Players") and get("state") in [Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER]:
#			return false # no hitting ceiling in sequences
		return true
	else:
		return false
		
		
func is_on_ground(soft_platform_dbox, checklist = null): # return true if standing on solid/soft floor
	
	var to_check := []
	if checklist == null:
		to_check = ["SolidPlatforms", "SoftPlatforms"]
	else:
		if "SolidPlatforms" in checklist: to_check.append("SolidPlatforms")
		if "SoftPlatforms" in checklist: to_check.append("SoftPlatforms")
		if to_check.size() == 0: return false
		
	if Detection.detect_bool([soft_platform_dbox], to_check, Vector2.DOWN) and \
			!Detection.detect_bool([soft_platform_dbox], to_check) \
			and get("velocity").y >= 0: # is not considered on ground if moving upwards
		return true
	else:
		return false
			

func is_on_solid_ground(soft_platform_dbox):
	if Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms"], Vector2.DOWN) and \
			!Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms"]) \
			and get("velocity").y >= 0: # is not considered on ground if moving upwards
		if has_method("check_passthrough") and call("check_passthrough"):
			return false
		return true
	else:
		return false
		
	
func is_on_soft_ground(soft_platform_dbox): # return true if standing on soft floor
	if Detection.detect_bool([soft_platform_dbox], ["SoftPlatforms"], Vector2.DOWN) and \
			!Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms", "SoftPlatforms"]) \
			and get("velocity").y >= 0: # is not considered on ground if moving upwards
		return true
	else:
		return false


func snap_up(collision_box, dashland_dbox): # move character upwards till dashland_dbox stop detecting soft platforms, called by Character.gd
	var max_movement = dashland_dbox.rect_size.y
	for x in max_movement:
		# dashland_dbox stopped detecting soft platforms, snap complete
		if !Detection.detect_bool([dashland_dbox], ["SoftPlatforms"]):
			get("velocity").y = 0 # reset vertical velocity
			call("set_true_position")
			return true
		# else if no solid platform above, move up 1 pixel
		elif !Detection.detect_bool([collision_box], ["SolidPlatforms"], Vector2.UP):
			position.y -= 1
		else: # hit a solid platform, stop immediately, revert all movement
			position.y += x
			return false
	# if fail to snap up after moving the max allowed distance, return to starting position
	position.y += max_movement
	return false
	


		
	
