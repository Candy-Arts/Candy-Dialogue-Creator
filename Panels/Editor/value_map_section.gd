#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyValueMapSection
extends VBoxContainer

var spec: Dictionary = {}
var map_path: Array = []
var line_path: Array = []
#^ Ids from the top level down to this map, included (see CandyFieldForm):
var schema_path: Array = []

var _context: Dictionary = {}
var _entries_box: VBoxContainer
var _keys: Array = []          #/ Keys the entries were built for, in order
var _widgets: Array = []       #/ Each entry's value CandyFieldWidget
var _message: Label            #/ Beside the title


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
	var map := _map()
	var keys: Array = []
	var values: Array = []
	for key in map:
		keys.append(str(key))
		values.append(map[key])
	if keys != _keys:
		_rebuild(keys)
		_keys = keys
	for i in values.size():
		_widgets[i].set_value(values[i])
	_show_checks()


func _entry_label() -> String:
	if spec.has("entry_label"):
		return CandyLocale.t(str(spec["entry_label"]))
	return CandyLocale.t("entry")


#& Entries

func _rebuild(keys: Array) -> void:
	for child in _entries_box.get_children():
		_entries_box.remove_child(child)
		child.queue_free()
	_widgets.clear()
	for key in keys:
		_build_entry(str(key))


#* Build an entry like a form field, its name over its widget:
func _build_entry(key: String) -> void:
	var row := VBoxContainer.new()
	row.theme_type_variation = CandyThemeDefaults.COMPACT_VBOX
	_entries_box.add_child(row)

	var header := HBoxContainer.new()
	header.theme_type_variation = CandyThemeDefaults.ROOMY_HBOX
	row.add_child(header)

	var label := Label.new()
	label.text = key
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	header.add_child(label)

	var remove_button := CandyIconButton.new(&"remove", CandyThemeDefaults.ICONS, "×", CandyLocale.t("Remove %s") % key)
	remove_button.pressed.connect(_confirm_remove.bind(key))
	header.add_child(remove_button)

	var entry_spec: Dictionary = CandySchemas.value_spec(spec, key)
	var widget := CandyWidgets.instantiate_field(str(entry_spec.get("widget", CandyWidgets.DEFAULT_FIELD_WIDGET)))
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	widget.value_committed.connect(func(value: Variant): _write(map_path + [key], value))
	row.add_child(widget)
	widget.field_path = map_path + [key]
	widget.bind_spec(entry_spec, _context)
	var buttons = _context.get("value_buttons", {})
	if buttons is Dictionary:
		widget.add_value_actions(bool(buttons.get("clear", false)), bool(buttons.get("reset", false)))
	widget.lock_key = CandyFieldForm.schema_key(schema_path)
	var locked_fields = _context.get("locked_fields", {})
	if locked_fields is Dictionary and locked_fields.has(widget.lock_key):
		widget.set_locked(true)
	_widgets.append(widget)


#& Edits

func _on_add_pressed() -> void:
	if line_path.is_empty():
		return
	var map := _map()
	var key: String = CandyDialogue.numbered_name(map.keys(), str(spec.get("entry_prefix", "Entry")))
	var new_map := map.duplicate()
	new_map[key] = CandySchemas.field_default(CandySchemas.value_spec(spec, key), str(_context.get("line_type", "")))
	_write(map_path, new_map)


#* Remove an entry once the user confirms:
func _confirm_remove(key: String) -> void:
	if line_path.is_empty():
		return
	CandyConfirmPrompt.ask_remove(self, _entry_label(), key, func():
		var map := _map()
		if map.has(key):
			var new_map := map.duplicate()
			new_map.erase(key)
			_write(map_path, CandyDialogue.renumbered(new_map, str(spec.get("entry_prefix", "Entry")))))


#& Checks

#* Show what the map's "checks" find, beside its title:
func _show_checks() -> void:
	if not spec.get("checks") is Array:
		return
	var context := CandyCheckContext.new("", spec)
	context.checks_value = false
	context.data = _map()
	context.line_type = str(_context.get("line_type", ""))
	context.line_path = line_path
	context.field_path = map_path
	context.form_context = _context
	var level: Array = map_path.slice(0, map_path.size() - 1)
	context.set_readers(func(id: String) -> Variant: return _read(level + [id]), Callable())
	CandyChecks.show_messages(_message, CandyChecks.messages(spec, context))


#& Data

func _map() -> Dictionary:
	var value = _read(map_path)
	if value is Dictionary:
		return value
	return {}


func _read(path: Array) -> Variant:
	var reader = _context.get("field_reader")
	if reader is Callable and reader.is_valid():
		return reader.call(line_path, path)
	return CandyDialogue.get_field(line_path, path, null)


func _write(path: Array, value: Variant) -> void:
	if line_path.is_empty():
		return
	var writer = _context.get("field_writer")
	if writer is Callable and writer.is_valid():
		writer.call(line_path, path, value)
	else:
		CandyDialogue.set_field(line_path, path, value)
