## Converts v2.x node data into v3.x node data for loading old projects.
class_name NodeConverter extends RefCounted


## Reads raw node data and returns a node instance of the new type.
## Returns the original dictionary if nothing to convert.
func convert_node(node_dict: Dictionary) -> Dictionary:
	match node_dict.get("$type"):
		"NodeAction": return convert_action(node_dict)
		"NodeDiceRoll": return convert_dice_roll(node_dict)
	return node_dict


func convert_action(dict: Dictionary) -> Dictionary:
	var action_dict = dict.get("Action")
	if action_dict:
		var value = action_dict.get("Value")
		dict.erase("Action")
		
		var action_type = action_dict.get("$type")
		match action_type:
			"ActionOption":
				dict["$type"] = "NodeSetter"
				dict["SetType"] = "Option"
				dict["OptionID"] = action_dict.get("OptionID")
				dict["Enable"] = value
			"ActionVariable":
				dict["$type"] = "NodeSetter"
				dict["SetType"] = "Variable"
				dict["Variable"] = action_dict.get("Variable")
				dict["Operator"] = action_dict.get("Operator")
				dict["Value"] = value
			"ActionCustom":
				match action_dict.get("CustomType"):
					"PlayAudio":
						dict["$type"] = "NodeAudio"
						dict["Loop"] = action_dict.get("Loop")
						dict["Volume"] = action_dict.get("Volume")
						dict["Pitch"] = action_dict.get("Pitch")
						dict["Audio"] = value
					"UpdateBackground":
						dict["$type"] = "NodeBackground"
						dict["Image"] = value
					"Other":
						dict["Action"] = value
						dict["Arguments"] = []
			"ActionTimer":
				dict["$type"] = "NodeWait"
				dict["Time"] = value
	
	return dict


func convert_dice_roll(dict: Dictionary) -> Dictionary:
	var pass_chance = dict.get("Target", 50)
	var fail_chance = 100 - pass_chance
	
	var pass_dict = { "Weight": pass_chance, "NextID": dict.get("PassID", -1) }
	var fail_dict = { "Weight": fail_chance, "NextID": dict.get("FailID", -1) }
	if pass_chance >= fail_chance:
		pass_dict["ID"] = 0
		fail_dict["ID"] = 1
		dict["Outputs"] = [pass_dict, fail_dict]
	else:
		fail_dict["ID"] = 0
		pass_dict["ID"] = 1
		dict["Outputs"] = [fail_dict, pass_dict]
	
	dict["$type"] = "NodeRandom"
	dict.erase("Skill")
	dict.erase("Target")
	dict.erase("PassID")
	dict.erase("FailID")
	return dict


func convert_characters(list: Array) -> Array:
	var all_ids: Array = []
	
	for character in list:
		if character.has("Reference"):
			continue
		
		all_ids.append(character.get("ID"))
	
	for character in list:
		if not character.has("Reference"):
			continue
		var list_idx: int = list.find(character)
		
		var character_name: String = character.get("Reference", "undefined")
		
		var new_character = {
			"ID": IDGen.generate(5),
			"EditorIndex": character.get("ID"),
			"Protected": character_name == "_NARRATOR",
			"Character": {
				"Name": character_name
			}
		}
		
		list[list_idx] = new_character
	
	return list
