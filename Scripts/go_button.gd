extends Button

@onready var main = get_node("/root/MainUI")

@export var conversation_node: Node
@export var block_node: Node


func _on_pressed() -> void:
	var conv_name = conversation_node.text_field.text.strip_edges()
	var block_name = block_node.text_field.text.strip_edges()
	var ctrl_held = Input.is_key_pressed(KEY_CTRL)

	#% If no conversation provided, use current:
	if conv_name == "":
		conv_name = globals.current_conversation

	if conv_name == "":
		return

	#% Create conversation if it doesn't exist:
	if not globals.dialogue.has(conv_name):
		var comment = globals.line_templates["§Comment"].duplicate(true)
		comment["Color"] = var_to_str(globals.line_colors["§Comment"]["Text"])
		if block_name != "":
			globals.dialogue[conv_name] = {block_name: {"Text": [{"§Comment": comment}]}}
		else:
			globals.dialogue[conv_name] = {globals.block_default_name: {"Text": [{"§Comment": comment}]}}

	#% Create block if it doesn't exist in the conversation:
	elif block_name != "" and not globals.dialogue[conv_name].has(block_name):
		var comment = globals.line_templates["§Comment"].duplicate(true)
		comment["Color"] = var_to_str(globals.line_colors["§Comment"]["Text"])
		globals.dialogue[conv_name][block_name] = {"Text": [{"§Comment": comment}]}

	if not ctrl_held:
		#% Select conversation and block:
		globals.current_conversation = conv_name
		globals.current_block = block_name if block_name != "" else globals.dialogue[conv_name].keys()[0]
		main._suppress_undo_save = true
		main.update_conversation_selector(true)
		main._suppress_undo_save = false
		main.hide_line_data(false)
	else:
		main._suppress_undo_save = true
		main.update_conversation_selector(true)
		main._suppress_undo_save = false


	main.save_undo_step()

