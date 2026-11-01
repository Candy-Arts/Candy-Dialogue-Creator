#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyListSection
extends VBoxContainer


var spec: Dictionary = {}
var base_path: Array = []
var line_path: Array = []
#^ Ids from the top level down to this list, included (see CandyFieldForm):
var schema_path: Array = []

var _context: Dictionary = {}
var _entries_box: VBoxContainer
var _frames: Array = []         #/ PanelContainer per entry, in order
var _forms: Array = []          #/ CandyFieldForm per entry, in order; null until shown
var _form_holders: Array = []   #/ Where each entry's form goes
var _entry_messages: Array = []  #/ Message Label per entry, or null without "entry_checks"
var _message: Label             #/ Beside the title
var _signature: Array = []
#^ Types of the map entry this list sits in (see CandyFieldForm):
var _entry_types: Array = []


func setup(p_spec: Dictionary, p_base_path: Array, context: Dictionary, p_schema_path: Array = []) -> void:
	spec = p_spec
	base_path = p_base_path.duplicate()
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
	label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	header.add_child(label)

	_message = CandyChecks.new_message_label()
	header.add_child(_message)

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
	var array = CandyDialogue.get_field(line_path, base_path, [])
	if not array is Array:
		array = []

	var signature := _signature_of(array)
	if signature != _signature:
		_rebuild(array)
		_signature = signature

	for i in _forms.size():
		#Ł Field Tree focus - show only the focused entry (none if nothing selected):
		_frames[i].visible = CandyFieldForm.entry_in_focus(_context, base_path + [i])
		if _frames[i].visible:
			_show_entry_checks(i, array)
			_form_at(i).bind_line(line_path)
	_show_checks(array)


#* Count plus names - a rename or add/remove rebuilds, a value edit doesn't:
func _signature_of(array: Array) -> Array:
	var result: Array = []
	for entry in array:
		if entry is Dictionary and entry.size() > 0 and _is_named():
			result.append(str(entry.keys()[0]))
		else:
			result.append("")
	return result


#* What an entry is called, as shown ("layer"):
func _entry_label() -> String:
	if spec.has("entry_label"):
		return CandyLocale.t(str(spec["entry_label"]))
	return CandyLocale.t("entry")


func _is_named() -> bool:
	return str(spec.get("entry", "")) == "named"


func _rebuild(array: Array) -> void:
	for child in _entries_box.get_children():
		_entries_box.remove_child(child)
		child.queue_free()
	_frames.clear()
	_forms.clear()
	_form_holders.clear()
	_entry_messages.clear()

	for index in array.size():
		_build_entry(index, array.size())


func _build_entry(index: int, count: int) -> void:
	var frame := PanelContainer.new()
	_entries_box.add_child(frame)
	_frames.append(frame)

	var body := VBoxContainer.new()
	frame.add_child(body)

	var header := HBoxContainer.new()
	body.add_child(header)

	var entry_message: Label = null
	if _is_named():
		var name_edit := LineEdit.new()
		name_edit.text = str(CandyDialogue.get_field(line_path, base_path + [index, CandyDialogue.ENTRY_NAME], ""))
		name_edit.tooltip_text = CandyLocale.t("Name of this %s. Must be unique in the list.") % _entry_label()
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_edit.text_submitted.connect(func(text: String): _commit_name(index, text, name_edit))
		name_edit.focus_exited.connect(func(): _commit_name(index, name_edit.text, name_edit))
		header.add_child(name_edit)
		if spec.get("entry_checks") is Array:
			entry_message = CandyChecks.new_message_label()
			header.add_child(entry_message)
	else:
		var label := Label.new()
		var entry_label := CandyLocale.t("Entry")
		if spec.has("entry_label"):
			entry_label = CandyLocale.t(str(spec["entry_label"]))
		label.text = "%s %d" % [entry_label, index]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(label)
	_entry_messages.append(entry_message)

	header.add_child(_tool_button(&"move_up", "^", CandyLocale.t("Move up"), index > 0,
		func(): CandyDialogue.move_entry(line_path, base_path, index, index - 1)))
	header.add_child(_tool_button(&"move_down", "v", CandyLocale.t("Move down"), index < count - 1,
		func(): CandyDialogue.move_entry(line_path, base_path, index, index + 1)))
	header.add_child(_tool_button(&"remove", "×", CandyLocale.t("Remove"), true, _confirm_remove.bind(index)))

	var indent := MarginContainer.new()
	indent.theme_type_variation = CandyThemeDefaults.INDENT
	body.add_child(indent)
	_form_holders.append(indent)
	_forms.append(null)


#* An entry's form, built on first use:
func _form_at(index: int) -> CandyFieldForm:
	if _forms[index] != null:
		return _forms[index]
	var entry_path := base_path + [index]
	if _is_named():
		entry_path.append(CandyDialogue.ENTRY_VALUE)
	var form := CandyFieldForm.new()
	_form_holders[index].add_child(form)
	form.build(_sub_fields(), entry_path, _context, schema_path)
	form.set_entry_types(_entry_types)
	_forms[index] = form
	return form


#& Checks

#* Show what the list's "checks" find, beside its title:
func _show_checks(array: Array) -> void:
	if not spec.get("checks") is Array:
		return
	var context := _check_context("")
	context.checks_value = false
	context.data = array
	CandyChecks.show_messages(_message, CandyChecks.messages(spec, context))


#* Show what "entry_checks" find in a named entry's name, beside it:
func _show_entry_checks(index: int, array: Array) -> void:
	if index >= _entry_messages.size() or _entry_messages[index] == null:
		return
	var entry_name := str(CandyDialogue.get_field(line_path, base_path + [index, CandyDialogue.ENTRY_NAME], ""))
	var context := _check_context(entry_name)
	context.checks_value = false
	context.field_path = base_path + [index, CandyDialogue.ENTRY_NAME]
	context.data = CandyDialogue.get_field(line_path, base_path + [index, CandyDialogue.ENTRY_VALUE], {})
	context.container = array
	CandyChecks.show_messages(_entry_messages[index], CandyChecks.messages(spec, context, "entry_checks"))


func _check_context(value: String) -> CandyCheckContext:
	var context := CandyCheckContext.new(value, spec)
	context.line_type = str(_context.get("line_type", ""))
	context.line_path = line_path
	context.field_path = base_path
	context.entry_types = _entry_types
	context.form_context = _context
	return context


func set_entry_types(types: Array) -> void:
	_entry_types = types
	for form in _forms:
		if form != null:
			form.set_entry_types(types)


#* An icon button, with fallback_text for a theme with no icon:
func _tool_button(icon_name: StringName, fallback_text: String, tooltip: String, enabled: bool,
		handler: Callable) -> Button:
	var button := CandyIconButton.new(icon_name, CandyThemeDefaults.ICONS, fallback_text, tooltip)
	button.disabled = not enabled
	button.pressed.connect(handler)
	return button


func _commit_name(index: int, text: String, edit: LineEdit) -> void:
	if line_path.is_empty():
		return
	if CandyDialogue.set_entry_name(line_path, base_path, index, text):
		return
	#% Rejected (empty or used) - restore the stored name:
	var current := str(CandyDialogue.get_field(line_path, base_path + [index, CandyDialogue.ENTRY_NAME], ""))
	if edit.text != current:
		edit.text = current


#* Remove an entry once the user confirms:
func _confirm_remove(index: int) -> void:
	if line_path.is_empty():
		return
	var target_line := line_path.duplicate()
	var entry_name := ""
	if _is_named():
		entry_name = str(CandyDialogue.get_field(target_line, base_path + [index, CandyDialogue.ENTRY_NAME], ""))
	CandyConfirmPrompt.ask_remove(self, _entry_label(), entry_name, func():
		var target := index
		#Ł Find a named entry again by name, in case the list changed meanwhile:
		if entry_name != "":
			target = CandyDialogue.entry_names(target_line, base_path).find(entry_name)
		if target >= 0:
			CandyDialogue.remove_entry(target_line, base_path, target))


func _on_add_pressed() -> void:
	if line_path.is_empty():
		return
	var template := CandySchemas.entry_defaults(spec)
	var entry_name := ""
	if _is_named():
		entry_name = str(spec.get("entry_prefix", "Entry")) + "_1"
	CandyDialogue.add_entry(line_path, base_path, entry_name, template)


func _sub_fields() -> Array:
	var sub = spec.get("fields", [])
	if sub is Array:
		return sub
	return []