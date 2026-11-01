#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyMapSection
extends VBoxContainer

const UNKNOWN_TYPE_TEXT := "Unknown type"	#/ translatable

var spec: Dictionary = {}
var map_path: Array = []
var line_path: Array = []
#^ Ids from the top level down to this map, included (see CandyFieldForm):
var schema_path: Array = []

var _context: Dictionary = {}
var _entries_box: VBoxContainer
var _keys: Array = []           #/ Keys the entries were built for, in order
var _frames: Array = []         #/ PanelContainer per entry
var _forms: Array = []          #/ CandyFieldForm per entry; null until shown
var _form_holders: Array = []   #/ Where each entry's form goes
var _name_edits: Array = []     #/ CandyLineEditWidget per entry (null for a command)
var _type_labels: Array = []    #/ Label per entry, or null when the map has no types
var _entry_messages: Array = []  #/ Message Label per entry, or null without "entry_checks"
var _message: Label             #/ Beside the title


func setup(p_spec: Dictionary, p_map_path: Array, context: Dictionary, p_schema_path: Array = []) -> void:
	spec = p_spec
	map_path = p_map_path.duplicate()
	schema_path = p_schema_path.duplicate()
	_context = context
	theme_type_variation = CandyThemeDefaults.COMPACT_VBOX

	var header := HBoxContainer.new()
	add_child(header)

	header.add_child(CandyFieldHelpButton.new(spec))

	var label := Label.new()
	label.text = str(spec.get("id", ""))
	if spec.has("label"):
		label.text = CandyLocale.t(str(spec["label"]))
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	header.add_child(label)

	_message = CandyChecks.new_message_label()
	header.add_child(_message)

	if not CandySchemas.is_command_map(spec):
		var add_button := Button.new()
		add_button.text = "+"
		add_button.tooltip_text = CandyLocale.t("Add %s") % _entry_label()
		add_button.focus_mode = Control.FOCUS_NONE
		add_button.pressed.connect(_on_add_pressed)
		header.add_child(add_button)

	var indent := MarginContainer.new()
	indent.theme_type_variation = CandyThemeDefaults.INDENT
	add_child(indent)

	_entries_box = VBoxContainer.new()
	indent.add_child(_entries_box)


func bind_line(p_line_path: Array) -> void:
	line_path = p_line_path.duplicate()
	var keys := CandyDialogue.map_keys(line_path, map_path)
	if keys != _keys:
		_rebuild(keys)
		_keys = keys

	for i in _forms.size():
		#Ł Field Tree focus - show only the focused entry:
		#? A command map has no rows there, so its command stays shown.
		if CandySchemas.is_command_map(spec):
			_frames[i].visible = CandyFieldForm.in_focus(_context, map_path + [_keys[i]])
		else:
			_frames[i].visible = CandyFieldForm.entry_in_focus(_context, map_path + [_keys[i]])
		if not _frames[i].visible:
			continue
		var types := CandySchemas.entry_types(spec, str(_keys[i]))
		_show_types(i, types)
		_show_entry_checks(i)
		var form := _form_at(i)
		form.set_entry_types(types)
		form.bind_line(line_path)
	_show_checks()


func _entry_label() -> String:
	if spec.has("entry_label"):
		return CandyLocale.t(str(spec["entry_label"]))
	return CandyLocale.t("entry")


func _has_types() -> bool:
	return str(spec.get("entry_type", "")) != ""


#& Entries

func _rebuild(keys: Array) -> void:
	for child in _entries_box.get_children():
		_entries_box.remove_child(child)
		child.queue_free()
	_frames.clear()
	_forms.clear()
	_form_holders.clear()
	_name_edits.clear()
	_type_labels.clear()
	_entry_messages.clear()

	for index in keys.size():
		_build_entry(index, keys)


func _build_entry(index: int, keys: Array) -> void:
	var key := str(keys[index])

	var frame := PanelContainer.new()
	_entries_box.add_child(frame)
	_frames.append(frame)

	var body := VBoxContainer.new()
	frame.add_child(body)

	var header := HBoxContainer.new()
	body.add_child(header)

	if CandySchemas.is_command_map(spec):
		#? The key is the command - no renaming.
		var command_title := Label.new()
		command_title.text = CandyLocale.command_title(CandySchemas.get_title(key))
		command_title.tooltip_text = key
		command_title.mouse_filter = Control.MOUSE_FILTER_PASS
		command_title.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
		command_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(command_title)
		_name_edits.append(null)
	else:
		var name_edit := CandyLineEditWidget.new()
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#? Addressed like a named list's name, so a dropdown can read the entry's fields.
		name_edit.field_path = map_path + [key, CandyDialogue.ENTRY_NAME]
		name_edit.bind_spec(_name_spec(), _context)
		name_edit.set_value(key)
		name_edit.value_committed.connect(func(value: Variant): _commit_name(key, str(value), name_edit))
		header.add_child(name_edit)
		_name_edits.append(name_edit)

	var entry_message: Label = null
	if spec.get("entry_checks") is Array:
		entry_message = CandyChecks.new_message_label()
		header.add_child(entry_message)
	_entry_messages.append(entry_message)

	var type_label: Label = null
	if _has_types():
		type_label = Label.new()
		type_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
		type_label.theme_type_variation = CandyThemeDefaults.NOTE
		header.add_child(type_label)
	_type_labels.append(type_label)

	if not CandySchemas.is_command_map(spec):
		header.add_child(_tool_button(&"move_up", "^", CandyLocale.t("Move up"), index > 0,
			func(): CandyDialogue.move_map_entry(line_path, map_path, key, index - 1)))
		header.add_child(_tool_button(&"move_down", "v", CandyLocale.t("Move down"), index < keys.size() - 1,
			func(): CandyDialogue.move_map_entry(line_path, map_path, key, index + 1)))
		header.add_child(_tool_button(&"remove", "×", CandyLocale.t("Remove"), true, _confirm_remove.bind(key)))

	var indent := MarginContainer.new()
	indent.theme_type_variation = CandyThemeDefaults.INDENT
	body.add_child(indent)
	_form_holders.append(indent)
	_forms.append(null)


#* An entry's form, built on first use:
func _form_at(index: int) -> CandyFieldForm:
	if _forms[index] != null:
		return _forms[index]
	var key := str(_keys[index])
	var form := CandyFieldForm.new()
	_form_holders[index].add_child(form)
	form.build(_sub_fields(key), map_path + [key], _context, schema_path)
	_forms[index] = form
	return form


func _show_types(index: int, types: Array) -> void:
	var label = _type_labels[index]
	if label == null:
		return
	var hint := CandyLocale.t(str(spec.get("entry_type_hint", "")))
	if types.is_empty():
		label.text = CandyLocale.t(UNKNOWN_TYPE_TEXT)
		label.tooltip_text = CandyLocale.t("Every setting is shown, since this %s's type isn't known.") % _entry_label()
	else:
		var names: PackedStringArray = []
		for type in types:
			names.append(str(type).capitalize())
		label.text = ", ".join(names)
		label.tooltip_text = CandyLocale.t("Only the settings this type uses are shown.")
	if hint != "":
		label.tooltip_text += "\n" + hint


#& Checks

#* Show what the map's "checks" find, beside its title:
func _show_checks() -> void:
	if not spec.get("checks") is Array:
		return
	var context := _check_context("")
	context.checks_value = false
	context.data = CandyDialogue.get_field(line_path, map_path, {})
	CandyChecks.show_messages(_message, CandyChecks.messages(spec, context))


#* Show what "entry_checks" find in an entry's name, beside it:
func _show_entry_checks(index: int) -> void:
	var label = _entry_messages[index]
	if label == null:
		return
	var key := str(_keys[index])
	var context := _check_context(key)
	context.checks_value = false
	context.field_path = map_path + [key, CandyDialogue.ENTRY_NAME]
	context.data = CandyDialogue.get_field(line_path, map_path + [key], {})
	context.container = CandyDialogue.get_field(line_path, map_path, {})
	CandyChecks.show_messages(label, CandyChecks.messages(spec, context, "entry_checks"))


func _check_context(value: String) -> CandyCheckContext:
	var context := CandyCheckContext.new(value, spec)
	context.line_type = str(_context.get("line_type", ""))
	context.line_path = line_path
	context.field_path = map_path
	context.form_context = _context
	return context


#* An icon button, with fallback_text for a theme with no icon:
func _tool_button(icon_name: StringName, fallback_text: String, tooltip: String, enabled: bool,
		handler: Callable) -> Button:
	var button := CandyIconButton.new(icon_name, CandyThemeDefaults.ICONS, fallback_text, tooltip)
	button.disabled = not enabled
	button.pressed.connect(handler)
	return button


#* The spec entry names are edited with ("entry_dropdown" gives a dropdown):
func _name_spec() -> Dictionary:
	var name_spec := {"tooltip": CandyLocale.t("Name of this %s. Must be unique.") % _entry_label()}
	if spec.get("entry_dropdown") is Dictionary:
		name_spec["dropdown"] = spec["entry_dropdown"]
	return name_spec


func _commit_name(key: String, text: String, edit: CandyLineEditWidget) -> void:
	if line_path.is_empty() or text.strip_edges() == key:
		return
	if CandyDialogue.rename_map_entry(line_path, map_path, key, text):
		return
	#% Refused (empty or used) - restore the stored name:
	if is_instance_valid(edit) and str(edit.get_value()) != key:
		edit.set_value_forced(key)


#* Remove an entry once the user confirms:
func _confirm_remove(key: String) -> void:
	if line_path.is_empty():
		return
	var target_line := line_path.duplicate()
	CandyConfirmPrompt.ask_remove(self, _entry_label(), key, func():
		CandyDialogue.remove_map_entry(target_line, map_path, key))


func _on_add_pressed() -> void:
	if line_path.is_empty():
		return
	var base_name := str(spec.get("entry_prefix", "Entry")) + "_1"
	var key := CandyDialogue.add_map_entry(line_path, map_path, base_name, CandySchemas.entry_defaults(spec))
	#Ł Entries were rebuilt - start naming the new one:
	var index := _keys.find(key)
	if key != "" and index >= 0 and index < _name_edits.size():
		var edit: CandyLineEditWidget = _name_edits[index]
		if is_instance_valid(edit):
			edit.start_editing()


#* An entry's fields: the map's, or its command's in a command map:
func _sub_fields(key: String) -> Array:
	return CandySchemas.map_entry_fields(spec, key, CandyDialogue.get_field(line_path, map_path + [key], {}))
