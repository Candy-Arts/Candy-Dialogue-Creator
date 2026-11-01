#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTestStartPopup
extends PopupPanel

#^ The fields' labels, by CandyTestRun.START_FIELDS:
const LABELS := {
	"Scene": "Scene",      #/ translatable
	"Conversation": "Conversation",      #/ translatable
	"Block": "Block",      #/ translatable
	"Line": "Line",      #/ translatable
}
const PLACEHOLDERS := {
	"Scene": "Candy Wizard's (its Test tool)",      #/ translatable
	"Conversation": "The first conversation",      #/ translatable
	"Block": "The first block",      #/ translatable
	"Line": "The first line",      #/ translatable
}
const TOOLTIPS := {
	"Scene": "The testing scene to run, from the Testing scenes folder. Its root must export dialogue, conversation, block and line, as Candy DE's Testing_Scene.gd does. Right-click tests use it too.\nEmpty: the scene chosen in Candy Wizard's Test tool.",      #/ translatable
	"Conversation": "The conversation to start in. Empty: the dialogue's first.",      #/ translatable
	"Block": "The block to start in. Empty: the conversation's first.",      #/ translatable
	"Line": "The line to start at: its number, or an LM line's Reference. Empty: the first line.",      #/ translatable
}
const SCENE_EXTENSION := "tscn"
#^ Longest line description in a Line menu item:
const LINE_TEXT_LENGTH := 70

var _edits := {}    #/ Field -> LineEdit
var _menu: PopupMenu
var _menu_values: Array = []
var _menu_field := ""


func _init() -> void:
	var box := VBoxContainer.new()
	add_child(box)

	var heading := Label.new()
	heading.text = CandyLocale.t("Test")
	heading.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	box.add_child(heading)

	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	for field in CandyTestRun.START_FIELDS:
		var label := Label.new()
		label.text = CandyLocale.t(str(LABELS.get(field, field)))
		label.tooltip_text = CandyLocale.t(TOOLTIPS[field])
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(label)

		var row := HBoxContainer.new()
		grid.add_child(row)
		var button := CandyIconButton.new(&"arrow", &"OptionButton", "v", CandyLocale.t("Pick a value"))
		button.pressed.connect(_open_menu.bind(field, button))
		row.add_child(button)
		var edit := LineEdit.new()
		edit.custom_minimum_size.x = 280
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.placeholder_text = CandyLocale.t(PLACEHOLDERS[field])
		edit.tooltip_text = CandyLocale.t(TOOLTIPS[field])
		edit.clear_button_enabled = true
		edit.text_submitted.connect(func(_text: String): hide())
		row.add_child(edit)
		_edits[field] = edit

	var note := Label.new()
	note.text = CandyLocale.t("Test exports %s, then runs it in the Godot editor.\nCtrl+Click Test to export only.") % CandyDialogueExport.TEST_FILE
	note.theme_type_variation = CandyThemeDefaults.NOTE
	box.add_child(note)

	_menu = PopupMenu.new()
	_menu.id_pressed.connect(_on_menu_id)
	add_child(_menu)

	popup_hide.connect(_save)


#* Open under an anchor (screen coordinates), with the saved settings:
func open(anchor: Rect2i, host: Control) -> void:
	var start := CandyTestRun.saved_start()
	for field in CandyTestRun.START_FIELDS:
		_edits[field].text = start[field]
	CandyPopups.popup_at(self, anchor, host)


func _save() -> void:
	var start := {}
	for field in CandyTestRun.START_FIELDS:
		start[field] = _edits[field].text
	CandyTestRun.save_start(start)


#& Dropdowns

#* Open a field's menu, rebuilt on every press (follows project, dialogue, other fields):
func _open_menu(field: String, button: Control) -> void:
	_menu.clear()
	_menu_values.clear()
	_menu_field = field
	for item in _items(field):
		if item.has("separator"):
			_menu.add_separator(str(item["separator"]))
			continue
		_menu.add_item(str(item["label"]), _menu_values.size())
		_menu_values.append(str(item["value"]))
	var anchor := Rect2i(Vector2i(button.get_screen_position()), Vector2i(button.size))
	CandyPopups.popup_at(_menu, anchor, button)


func _on_menu_id(id: int) -> void:
	if id < 0 or id >= _menu_values.size():
		return
	_edits[_menu_field].text = _menu_values[id]


#* A field's menu items: {"label", "value"} or {"separator": title}:
func _items(field: String) -> Array:
	var items: Array = [{"label": CandyLocale.t(PLACEHOLDERS[field]), "value": ""}]
	var names: Array = []
	match field:
		"Scene":
			names = _scene_names()
		"Conversation":
			names = CandyDialogue.conversation_names()
		"Block":
			names = _blocks().keys()
		"Line":
			return items + _line_items()
	if not names.is_empty():
		items.append({"separator": ""})
	for item_name in names:
		items.append({"label": str(item_name), "value": str(item_name)})
	return items


#* Scenes of the Testing scenes folder, by path in it ("Shop/Test.tscn"):
func _scene_names() -> Array:
	var folder := CandyResources.resource_folder("Testing_Scenes")
	if folder == "" or not DirAccess.dir_exists_absolute(folder):
		return []
	return _scene_files(folder, "")


func _scene_files(folder: String, prefix: String) -> Array:
	var found: Array = []
	for file_name in DirAccess.get_files_at(folder):
		if file_name.get_extension().to_lower() == SCENE_EXTENSION:
			found.append(prefix + file_name)
	for sub_folder in DirAccess.get_directories_at(folder):
		found.append_array(_scene_files(folder.path_join(sub_folder), prefix + sub_folder + "/"))
	found.sort()
	return found


func _line_items() -> Array:
	var items: Array = []
	var markers: Array = []
	var block = _blocks().get(_chosen("Block", _blocks()))
	if not block is Dictionary:
		return items
	var lines = block.get(CandyDialogue.TEXT_KEY, [])
	if not lines is Array:
		return items
	if not lines.is_empty():
		items.append({"separator": CandyLocale.t("Lines")})
	for index in lines.size():
		var line = lines[index]
		if not line is Dictionary:
			continue
		var text := CandyDialogue.describe_line(line, index, CandyDialogue.DisplayMode.SHORT)
		if text.length() > LINE_TEXT_LENGTH:
			text = text.substr(0, LINE_TEXT_LENGTH - 1) + "…"
		items.append({"label": text, "value": str(index)})
		if CandyDialogue.line_type(line) == "LM":
			var marker := str(CandyDialogue.line_data(line).get("Reference", ""))
			if marker != "":
				markers.append({"label": marker, "value": marker})
	if not markers.is_empty():
		items.append({"separator": CandyLocale.t("Line Marks")})
		items.append_array(markers)
	return items


#* The chosen conversation's blocks in the open dialogue:
func _blocks() -> Dictionary:
	var blocks = CandyDialogue.dialogue.get(_chosen("Conversation", CandyDialogue.dialogue), {})
	if blocks is Dictionary:
		return blocks
	return {}


#* A field's value, or the first option when empty (what empty means):
func _chosen(field: String, options: Dictionary) -> String:
	var value: String = _edits[field].text.strip_edges()
	if value == "" and not options.is_empty():
		return str(options.keys()[0])
	return value
