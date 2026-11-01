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

const LEVELS := ["menu", "category", "choice", "timer"]


func get_items(config: Dictionary, _context: Dictionary) -> Array:
	var level := str(config.get("level", "menu"))
	if not LEVELS.has(level):
		return []
	var tags: Array = []
	for conversation in CandyDialogue.conversation_names():
		for block in CandyDialogue.block_names(conversation):
			for line in CandyDialogue.lines(conversation, block):
				_collect(line, level, tags)
	tags.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)

	var items: Array = []
	for tag in tags:
		items.append({"label": tag, "value": tag})
	return items


#* Collect the tags of every Choice_List, nested Commands included:
func _collect(commands: Dictionary, level: String, tags: Array) -> void:
	for command in commands:
		var data = commands[command]
		if not data is Dictionary:
			continue
		if str(command) == "Choice_List":
			_add_list_tags(data, level, tags)
		if data.get("Commands") is Dictionary:
			_collect(data["Commands"], level, tags)


func _add_list_tags(menu: Dictionary, level: String, tags: Array) -> void:
	if level == "menu":
		_add_tags(menu, tags)
	elif level == "timer":
		for timer in _entry_data(menu.get("Timers", [])):
			_add_tags(timer, tags)
	else:
		for category in _entry_data(menu.get("Categories", [])):
			if level == "category":
				_add_tags(category, tags)
			else:
				for choice in _entry_data(category.get("Choices", [])):
					_add_tags(choice, tags)


#* Add tags not listed yet:
func _add_tags(data: Dictionary, tags: Array) -> void:
	for tag in CandyProjectScripts.split_list(str(data.get("Tags", ""))):
		#? Case-insensitive, like Candy DE - listed once, as first found.
		var known := false
		for existing in tags:
			if str(existing).to_lower() == tag.to_lower():
				known = true
				break
		if not known:
			tags.append(tag)


#* Data of each entry of a named list:
#?   list: [{ "<name>": { ... } }, ...]
func _entry_data(list: Variant) -> Array:
	var entries: Array = []
	if not list is Array:
		return entries
	for wrapper in list:
		if wrapper is Dictionary and wrapper.size() > 0 and wrapper[wrapper.keys()[0]] is Dictionary:
			entries.append(wrapper[wrapper.keys()[0]])
	return entries
