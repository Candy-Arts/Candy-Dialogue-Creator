#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends RefCounted

const TARGET_FIELDS := ["Conversation", "Block", "Line"]


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	if context.line_path.size() < 3:
		return []
	var value := context.value.strip_edges()
	var part := str(config.get("part", ""))
	if value == "" and (part == "conversation" or part == "block"):
		return _default_notice(config, context, part)
	if CandyDialogue.is_preset_conversation(str(context.line_path[0])):
		return []
	match part:
		"conversation":
			if value != "" and not CandyDialogue.conversation_names().has(value):
				return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No conversation %s in this dialogue.") % value)]
		"block":
			var conversation := _conversation(config, context)
			if value != "" and conversation != "" and not CandyDialogue.block_names(conversation).has(value):
				return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No block {block} in {conversation}.").format({"block": value, "conversation": conversation}))]
		"line":
			return _line_messages(config, context, value)
	return []


#* What an empty Conversation or Block stands for:
func _default_notice(config: Dictionary, context: CandyCheckContext, part: String) -> Array:
	if bool(config.get("optional", false)):
		var fields = config.get("target_fields", TARGET_FIELDS)
		var has_target := false
		if fields is Array:
			for field in fields:
				if context.sibling(str(field)) != "":
					has_target = true
		if not has_target:
			return []
	if part == "conversation":
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Empty: the current conversation."))]
	var conversation := ""
	if config.has("conversation_field"):
		conversation = context.sibling(str(config["conversation_field"]))
	if conversation != "" and not context.is_unknown(conversation) and conversation != str(context.line_path[0]):
		return [CandyChecks.message(CandyChecks.NOTICE,
			CandyLocale.t("Empty: the block named {block} in {conversation}.").format({"block": str(context.line_path[1]), "conversation": conversation}))]
	return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Empty: the current block."))]


#* The target conversation, or "" when it isn't known or doesn't exist:
func _conversation(config: Dictionary, context: CandyCheckContext) -> String:
	var conversation := ""
	if config.has("conversation_field"):
		conversation = context.sibling(str(config["conversation_field"]))
	if context.is_unknown(conversation):
		return ""
	if conversation == "":
		conversation = str(context.line_path[0])
	if not CandyDialogue.conversation_names().has(conversation):
		return ""
	return conversation


#* Check the Line part:
func _line_messages(config: Dictionary, context: CandyCheckContext, value: String) -> Array:
	var conversation := _conversation(config, context)
	if conversation == "":
		return []
	var block := ""
	if config.has("block_field"):
		block = context.sibling(str(config["block_field"]))
	if context.is_unknown(block):
		return []
	if block == "":
		block = str(context.line_path[1])
	if not CandyDialogue.block_names(conversation).has(block):
		return []
	var lines := CandyDialogue.lines(conversation, block)

	var index := 0
	if value != "":
		if not CandyChecks.is_whole(value):
			for line in lines:
				if line is Dictionary and CandyDialogue.line_type(line) == "LM" \
						and str(CandyDialogue.line_data(line).get("Reference", "")) == value:
					return []
			return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No LM {reference} in {block}.").format({"reference": value, "block": block}))]
		index = value.to_int()

	var result: Array = []
	if index < 0:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Line numbers start at 0."))]
	if index >= lines.size():
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("{block} has no line {index}.").format({"block": block, "index": index}))]
	if bool(config.get("self", false)) and conversation == str(context.line_path[0]) \
			and block == str(context.line_path[1]) and index == int(context.line_path[2]):
		result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Targets this line itself: it runs over and over.")))
	if value != "":
		var description := CandyDialogue.describe_line(lines[index], index, CandyDialogue.DisplayMode.SHORT)
		var prefix := "%d | " % index
		description = description.trim_prefix(prefix).trim_suffix(":")
		result.append(CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Line {index}, counted from 0: {line}.").format({"index": index, "line": description})))
	return result
