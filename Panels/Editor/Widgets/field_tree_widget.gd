#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldTreeWidget
extends CandyAreaWidget

const ALL_ID := "all"
const DEFAULT_BUTTONS := "top"

var _root: VBoxContainer
var _list: CandyVariationList
var _buttons: HFlowContainer
#^ Between the add buttons and the list:
var _separator: HSeparator
var _settings: CandyFieldTreeSettings
var _line_path: Array = []
var _paths: Dictionary = {}    #/ row id -> tree path


func _on_configured() -> void:
	_root = VBoxContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme_type_variation = CandyThemeDefaults.COMPACT_VBOX
	add_child(_root)

	_buttons = HFlowContainer.new()
	_root.add_child(_buttons)

	_separator = HSeparator.new()
	_root.add_child(_separator)

	_list = CandyVariationList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.row_pressed.connect(_on_row_pressed)
	_root.add_child(_list)
	_place_buttons()

	var shared := field_selection()
	if shared != null:
		shared.changed.connect(_on_selection_changed)


func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	_rebuild()


#* Another line starts with no row selected:
func line_changing(_new_line_path: Array) -> void:
	var shared := field_selection()
	if shared != null:
		shared.clear(reference(), _line_type())


func _line_type() -> String:
	return str(context.get("line_type", ""))


func _specs() -> Array:
	if not CandyDialogue.is_line_path(_line_path):
		return []
	var line := CandyDialogue.line_at(_line_path)
	return CandySchemas.field_specs(_line_type(), CandyDialogue.line_data(line))


func _selected_tree_path() -> Array:
	var shared := field_selection()
	if shared == null:
		return []
	return shared.get_selected(reference(), _line_type())


#& Rows

func _rebuild() -> void:
	if _list == null:
		return
	_paths = {ALL_ID: []}
	var rows: Array = [{"id": ALL_ID, "text": CandyLocale.t("All"), "indent": 0, "disableable": false}]
	if CandyDialogue.is_line_path(_line_path):
		_add_rows(rows, _specs(), [], [], 0, [])
	_list.set_rows(rows)
	_list.selected_id = _selected_row_id()
	_rebuild_buttons()


#* Add a row per parent field in specs, then the rows inside it:
#? data_path: where specs sit in the line; tree_path: the selection they belong to;
#? types: those of the map entry they're in (CandySchemas.entry_types).
func _add_rows(rows: Array, specs: Array, data_path: Array, tree_path: Array, indent: int, types: Array) -> void:
	for spec in specs:
		if not (spec is Dictionary and spec.has("id")):
			continue
		if not CandySchemas.in_forms(spec) or not CandySchemas.suits_types(spec, types):
			continue
		var id := str(spec["id"])
		var sub := CandyFieldSelection.sub_fields(spec)
		match str(spec.get("widget", CandyWidgets.DEFAULT_FIELD_WIDGET)):
			"group":
				#? Group - no row, its repeatable fields at the parent's level.
				_add_rows(rows, sub, data_path + [id], tree_path + [id], indent, types)
			"list":
				var list_path := data_path + [id]
				var array = CandyDialogue.get_field(_line_path, list_path, [])
				if not array is Array:
					continue
				for index in array.size():
					var path := tree_path + [id, index]
					var entry_path := list_path + [index]
					var text := "%s %d" % [_entry_prefix(spec), index + 1]
					if CandySchemas.is_named_list(spec):
						text = str(CandyDialogue.get_field(_line_path, entry_path + [CandyDialogue.ENTRY_NAME], text))
						entry_path.append(CandyDialogue.ENTRY_VALUE)
					_add_row(rows, path, text, indent)
					_add_rows(rows, sub, entry_path, path, indent + 1, types)
			"map":
				if CandySchemas.is_value_map(spec):
					continue
				var map_path := data_path.duplicate()
				if not CandySchemas.is_root_map(spec):
					map_path.append(id)
				var keys := CandyDialogue.map_keys(_line_path, map_path)
				for index in keys.size():
					var path := tree_path + [id, index]
					var entry_path: Array = map_path + [keys[index]]
					#? An entry's fields can depend on the entry (a map of commands).
					var entry_fields := CandySchemas.map_entry_fields(spec, str(keys[index]),
						CandyDialogue.get_field(_line_path, entry_path, {}))
					if CandySchemas.is_command_map(spec):
						#? Like a group - no row, its repeatable fields at this level.
						_add_rows(rows, entry_fields, entry_path, path, indent, [])
						continue
					_add_row(rows, path, "%s %d" % [_entry_prefix(spec), index + 1], indent)
					_add_rows(rows, entry_fields, entry_path, path, indent + 1,
						CandySchemas.entry_types(spec, str(keys[index])))


func _add_row(rows: Array, tree_path: Array, text: String, indent: int) -> void:
	var id := JSON.stringify(tree_path)
	_paths[id] = tree_path
	rows.append({"id": id, "text": text, "indent": indent, "disableable": false})


#* The row of the current selection, "" for none:
func _selected_row_id() -> String:
	var shared := field_selection()
	if shared != null and not shared.has_selection(reference(), _line_type()):
		return ""
	var id := JSON.stringify(_selected_tree_path())
	if _paths.has(id):
		return id
	return ALL_ID		#/ No entry on this line, as the Fields widgets do


#* What an entry of this list or map is called ("Player"):
func _entry_prefix(spec: Dictionary) -> String:
	var prefix := str(spec.get("entry_prefix", ""))
	if prefix == "":
		prefix = str(spec.get("entry_label", "entry")).capitalize()
	return prefix


#& Add buttons

func _rebuild_buttons() -> void:
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()

	var specs := _specs()
	var selected := _selected_tree_path()
	for entry in _ordered_repeatables(specs):
		var spec: Dictionary = entry["spec"]
		var container = _container_tree_path(specs, entry["ids"], selected)
		var enabled := container is Array \
			and CandyFieldSelection.data_path(_line_path, specs, container) is Array

		var button := Button.new()
		#? The prefix names new entries in the data: only this label is translated.
		button.text = "+ %s" % CandyLocale.t(_entry_prefix(spec))
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = not enabled
		if enabled:
			button.tooltip_text = CandyLocale.t("Add %s") % CandyLocale.t(str(spec.get("entry_label", "entry")))
			button.pressed.connect(_add_entry.bind(spec, container))
		else:
			button.tooltip_text = CandyLocale.t("Select the %s to add it to first.") % CandyLocale.t(str(entry["owner"]))
		_buttons.add_child(button)

	_buttons.visible = _buttons.get_child_count() > 0
	_separator.visible = _buttons.visible


#* The list and map fields of specs, in "button_order", then the unlisted ones:
func _ordered_repeatables(specs: Array) -> Array:
	var repeatables: Array = []
	_collect_repeatables(specs, [], "", repeatables)
	var order = config.get("button_order", [])
	if not order is Array:
		return repeatables
	var ordered: Array = []
	for key in order:
		for entry in repeatables:
			if _repeatable_key(entry) == str(key) and not ordered.has(entry):
				ordered.append(entry)
	for entry in repeatables:
		if not ordered.has(entry):
			ordered.append(entry)
	return ordered


#* How "button_order" names a list or map field ("Categories/Choices"):
func _repeatable_key(entry: Dictionary) -> String:
	return CandyFieldForm.schema_key(entry["ids"])


#* The add buttons, in order, for Options - [{ "key", "label" }]:
func button_choices() -> Array:
	var result: Array = []
	for entry in _ordered_repeatables(CandySchemas.field_specs(_line_type())):
		result.append({"key": _repeatable_key(entry), "label": "+ %s" % _entry_prefix(entry["spec"])})
	return result


#* Collect every list and map field, with its ids path and what its owner entry is called:
func _collect_repeatables(specs: Array, parent_ids: Array, owner_label: String, result: Array) -> void:
	for spec in specs:
		if not (spec is Dictionary and spec.has("id")) or not CandySchemas.in_forms(spec):
			continue
		var ids := parent_ids + [str(spec["id"])]
		var inner_owner := owner_label
		match str(spec.get("widget", CandyWidgets.DEFAULT_FIELD_WIDGET)):
			"list", "map":
				if CandySchemas.is_command_map(spec) or CandySchemas.is_value_map(spec):
					continue  #/ Its command comes from Type, or its values have no fields
				result.append({"spec": spec, "ids": ids, "owner": owner_label})
				inner_owner = str(spec.get("entry_label", "entry"))
			"group":
				pass
			_:
				continue
		_collect_repeatables(CandyFieldSelection.sub_fields(spec), ids, inner_owner, result)


#* The tree path of the list or map at ids a new entry goes into, or null:
#?   ids ["Categories", "Choices"], selected ["Categories", 1, "Choices", 0]
#?   -> ["Categories", 1, "Choices"]
func _container_tree_path(specs: Array, ids: Array, selected: Array) -> Variant:
	var result: Array = []
	var level := specs
	for step in ids.size():
		var spec := CandyFieldSelection.spec_in(level, str(ids[step]))
		result.append(str(ids[step]))
		if step == ids.size() - 1:
			return result
		match str(spec.get("widget", CandyWidgets.DEFAULT_FIELD_WIDGET)):
			"list", "map":
				if selected.size() <= result.size() or selected.slice(0, result.size()) != result:
					return null		#/ The selection isn't inside one
				result.append(selected[result.size()])	#/ The entry on the way, from the selection
		level = CandyFieldSelection.sub_fields(spec)
	return null


func _add_entry(spec: Dictionary, container: Array) -> void:
	var line_path := _line_path.duplicate()
	var data_path = CandyFieldSelection.data_path(line_path, _specs(), container)
	if not data_path is Array:
		return
	var base_name := _entry_prefix(spec) + "_1"
	var template := CandySchemas.entry_defaults(spec)

	#? Adding rebinds this widget before the new entry is selected below.
	var index := -1
	if str(spec.get("widget", "")) == "map":
		var key := CandyDialogue.add_map_entry(line_path, data_path, base_name, template)
		if key != "":
			index = CandyDialogue.map_keys(line_path, data_path).find(key)
	else:
		var entry_name := ""
		if CandySchemas.is_named_list(spec):
			entry_name = base_name
		index = CandyDialogue.add_entry(line_path, data_path, entry_name, template)

	var shared := field_selection()
	if index >= 0 and shared != null:
		shared.select(reference(), _line_type(), container + [index])


func _place_buttons() -> void:
	var at_top := str(config.get("buttons", DEFAULT_BUTTONS)) != "bottom"
	#? Above or below the list, the separator between them.
	if at_top:
		_root.move_child(_buttons, 0)
		_root.move_child(_separator, 1)
	else:
		_root.move_child(_separator, _root.get_child_count() - 1)
		_root.move_child(_buttons, _root.get_child_count() - 1)


#& Input

func _on_row_pressed(id: String) -> void:
	var shared := field_selection()
	if shared == null:
		return
	shared.select(reference(), _line_type(), _paths.get(id, []))


func _on_selection_changed(changed_reference: String, line_type: String, _tree_path: Array) -> void:
	if changed_reference != reference() or line_type != _line_type():
		return
	_list.selected_id = _selected_row_id()
	_rebuild_buttons()


func has_settings() -> bool:
	return true


func open_settings() -> void:
	_open_settings()


func _open_settings() -> void:
	if _settings == null:
		_settings = CandyFieldTreeSettings.new()
		_settings.applied.connect(_on_settings_applied)
		add_child(_settings)
	_settings.open(config, button_choices())


func _on_settings_applied(new_config: Dictionary) -> void:
	var merged := config.duplicate(true)
	for key in new_config:
		merged[key] = new_config[key]
	save_config(merged)
	_place_buttons()
	_rebuild()
