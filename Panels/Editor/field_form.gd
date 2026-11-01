#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldForm
extends VBoxContainer

#^ How deep siblings' own visible_when are followed (rules depending on each other):
const MAX_RULE_DEPTH := 8

var line_path: Array = []
var base_path: Array = []
#^ Types of the map entry this form edits; [] shows every field:
var entry_types: Array = []
#^ Ids of the fields this form sits in, for "hidden_children":
var schema_path: Array = []

var _entries: Array = []      #/ { spec, id, path, node, widget + message | fields | list | map }
#^ Entry nodes and separators, in order - { node, separator }:
#? See CandyListSeparators.update_visibility().
var _items: Array = []
var _context: Dictionary = {}


func build(specs: Array, p_base_path: Array, context: Dictionary, p_schema_path: Array = []) -> void:
	base_path = p_base_path.duplicate()
	schema_path = p_schema_path.duplicate()
	_context = context

	for child in get_children():
		remove_child(child)
		child.queue_free()
	_entries.clear()
	_items.clear()

	for spec in _arranged(specs):
		if CandyListSeparators.is_separator(spec):
			var line := HSeparator.new()
			add_child(line)
			_items.append({"node": line, "separator": true, "id": str(spec)})
			continue
		if not (spec is Dictionary and spec.has("id")):
			continue
		match str(spec.get("widget", CandyWidgets.DEFAULT_FIELD_WIDGET)):
			"group":
				_add_group(spec)
			"list":
				_add_list(spec)
			"map":
				_add_map(spec)
			_:
				_add_field(spec)
		_items.append({"node": _entries[-1]["node"], "separator": false})


#* specs in the context's "child_order", separator ids among them:
func _arranged(specs: Array) -> Array:
	var orders = _context.get("child_order", {})
	var key := schema_key(schema_path)
	if schema_path.is_empty() or not orders is Dictionary or not orders.has(key):
		return specs			#/ Top-level form, or no stored order: as they are
	var by_id := {}
	var ids: Array = []
	for spec in specs:
		if spec is Dictionary and spec.has("id"):
			by_id[str(spec["id"])] = spec
			ids.append(str(spec["id"]))
	var result: Array = []
	for id in ordered_ids(ids, orders[key]):
		if CandyListSeparators.is_separator(id):
			result.append(id)
		else:
			result.append(by_id[id])
	return result


#* A parent's field ids (schema order) in their stored order, with separators:
static func ordered_ids(schema_ids: Array, stored: Variant) -> Array:
	var result: Array = []
	#@ Step 1 - Each stored id the schema still has:
	if stored is Array:
		for id in stored:
			var key := str(id)
			if result.has(key):
				continue
			if CandyListSeparators.is_separator(key) or schema_ids.has(key):
				result.append(key)
	#@ Step 2 - Then fields the order doesn't list yet:
	for id in schema_ids:
		if not result.has(str(id)):
			result.append(str(id))
	return result


#* Store the filtered-out field ids in the shared context, for every nested form:
func apply_hidden_fields(hidden_fields: Dictionary) -> void:
	_context["hidden_fields"] = hidden_fields


#* Set the map entry's types (applied on the next bind_line()):
func set_entry_types(types: Array) -> void:
	entry_types = types
	for entry in _entries:
		if entry.has("fields"):
			entry["fields"].set_entry_types(types)
		elif entry.has("list"):
			entry["list"].set_entry_types(types)


#* Push values into the form and re-evaluate visibility:
func bind_line(p_line_path: Array) -> void:
	line_path = p_line_path.duplicate()
	_context["line_path"] = line_path
	var hidden_fields: Dictionary = _context.get("hidden_fields", {})
	var hidden_children: Dictionary = _context.get("hidden_children", {})
	for entry in _entries:
		var key := schema_key(schema_path + [entry["id"]])
		var entry_is_visible := not hidden_fields.has(key) \
			and not hidden_children.has(key) \
			and in_focus(_context, entry["path"]) \
			and CandySchemas.suits_types(entry["spec"], entry_types) \
			and _evaluate_visibility(entry["spec"])
		entry["node"].visible = entry_is_visible
		if not entry_is_visible:
			continue
		if entry.has("widget"):
			var value = _read(entry["path"])
			entry["widget"].set_value(value)
			_show_checks(entry, value)
		elif entry.has("fields"):
			entry["fields"].bind_line(line_path)
		elif entry.has("list"):
			entry["list"].bind_line(line_path)
		elif entry.has("map"):
			entry["map"].bind_line(line_path)
	var hidden_separators: Dictionary = _context.get("hidden_separators", {})
	for item in _items:
		if bool(item["separator"]):
			item["hidden"] = hidden_separators.has(item["id"])
		else:
			item["shown"] = item["node"].visible
	CandyListSeparators.update_visibility(_items)


#* Whether the last bind_line() left any field shown:
func has_visible_fields() -> bool:
	for entry in _entries:
		if entry["node"].visible:
			return true
	return false


func _add_field(spec: Dictionary) -> void:
	var id := str(spec["id"])
	var row := VBoxContainer.new()
	row.theme_type_variation = CandyThemeDefaults.COMPACT_VBOX
	add_child(row)

	var header := HBoxContainer.new()
	header.theme_type_variation = CandyThemeDefaults.ROOMY_HBOX
	row.add_child(header)

	header.add_child(CandyFieldHelpButton.new(spec))

	var label := Label.new()
	label.text = id
	if spec.has("label"):
		label.text = CandyLocale.t(str(spec["label"]))
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	header.add_child(label)

	var message := CandyChecks.new_message_label()
	header.add_child(message)

	var widget := CandyWidgets.instantiate_field(str(spec.get("widget", CandyWidgets.DEFAULT_FIELD_WIDGET)))
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	widget.value_committed.connect(_on_value_committed.bind(id))
	widget.siblings_committed.connect(_on_siblings_committed)
	row.add_child(widget)
	widget.field_path = base_path + CandySchemas.data_path(spec)
	#? The context is shared and holds "line_path", so dropdown providers see the current line.
	widget.bind_spec(spec, _context)
	var buttons = _context.get("value_buttons", {})
	if buttons is Dictionary:
		widget.add_value_actions(bool(buttons.get("clear", false)), bool(buttons.get("reset", false)))
	widget.lock_key = schema_key(schema_path + [id])
	var locked_fields = _context.get("locked_fields", {})
	if locked_fields is Dictionary and locked_fields.has(widget.lock_key):
		widget.set_locked(true)

	_entries.append({"spec": spec, "id": id, "path": widget.field_path, "node": row,
		"widget": widget, "message": message})


#* Show what the field's checks find in value, beside its name:
func _show_checks(entry: Dictionary, value: Variant) -> void:
	var spec: Dictionary = entry["spec"]
	if not spec.get("checks") is Array:
		return
	var text := ""
	if value != null and not value is Dictionary and not value is Array:
		text = str(value)
	CandyChecks.show_messages(entry["message"], CandyChecks.messages(spec, _check_context(entry, text)))


#* The context one of this form's fields' checks run with:
func _check_context(entry: Dictionary, value: String) -> CandyCheckContext:
	var context := CandyCheckContext.new(value, entry["spec"])
	context.line_type = str(_context.get("line_type", ""))
	context.line_path = line_path
	context.field_path = entry["path"]
	context.entry_types = entry_types
	context.form_context = _context
	var own_path: Array = entry["path"]
	context.set_readers(
		func(id: String) -> Variant: return _read(_reference_path(id)),
		func(rule: Dictionary) -> bool: return _rule_holds(rule, 0, false, own_path, value))
	return context


func _add_group(spec: Dictionary) -> void:
	var id := str(spec["id"])
	var section := CandyGroupSection.new()
	add_child(section)
	section.setup(spec, base_path + [id], _context, schema_path + [id])
	_entries.append({"spec": spec, "id": id, "path": base_path + [id], "node": section,
		"fields": section.fields})


func _add_list(spec: Dictionary) -> void:
	var id := str(spec["id"])
	var section := CandyListSection.new()
	add_child(section)
	section.setup(spec, base_path + [id], _context, schema_path + [id])
	_entries.append({"spec": spec, "id": id, "path": base_path + [id], "node": section,
		"list": section})


#* Add a map section (value maps have their own):
func _add_map(spec: Dictionary) -> void:
	var id := str(spec["id"])
	var map_path: Array = base_path + CandySchemas.data_path(spec)
	if CandySchemas.is_value_map(spec):
		var value_section := CandyValueMapSection.new()
		add_child(value_section)
		value_section.setup(spec, map_path, _context, schema_path + [id])
		_entries.append({"spec": spec, "id": id, "path": map_path, "node": value_section, "map": value_section})
		return
	if CandySchemas.is_root_map(spec):			#/ Its entries are this level's keys: no step into a field
		map_path = base_path.duplicate()
	var section := CandyMapSection.new()
	add_child(section)
	section.setup(spec, map_path, _context, schema_path + [id])
	_entries.append({"spec": spec, "id": id, "path": map_path, "node": section, "map": section})


#* Whether data at path shows under the context's "focus_path":
static func in_focus(context: Dictionary, path: Array) -> bool:
	var focus = context.get("focus_path", [])
	if not focus is Array or focus.is_empty():
		return true
	var count := mini(focus.size(), path.size())
	return focus.slice(0, count) == path.slice(0, count)			#/ Leads to the focus (a list the focused entry is in) or sits inside it


#* Whether a list or map entry at path shows - in_focus(), but never with a null focus:
static func entry_in_focus(context: Dictionary, path: Array) -> bool:
	if context.has("focus_path") and context["focus_path"] == null:
		return false			#/ No entry's fields are built until a Field Tree row asks for them
	return in_focus(context, path)


#* Schema path key, e.g. "Players/Loops":
static func schema_key(ids: Array) -> String:
	return "/".join(PackedStringArray(ids))


#* Write a field (and the command it picks) as one undo step:
func _on_value_committed(value: Variant, id: String) -> void:
	if line_path.is_empty():
		return
	CandyDialogue.begin_step()
	var writer = _context.get("field_writer")
	if writer is Callable and writer.is_valid():
		writer.call(line_path, _path_of(id), value)
	else:
		CandyDialogue.set_field(line_path, _path_of(id), value)
	var map_id := str(_spec_of(id).get("command_map", ""))
	if map_id != "":
		_set_command(str(value).strip_edges(), base_path + [map_id])
	CandyDialogue.end_step()


#* Write the "siblings" a dropdown item set (see CandyDropdowns):
func _on_siblings_committed(values: Dictionary) -> void:
	if line_path.is_empty():
		return
	var writer = _context.get("field_writer")
	for id in values:
		if _spec_of(str(id)).is_empty():			#/ Only this form's own fields: unknown ids aren't added to the line
			continue
		var path := _path_of(str(id))
		if writer is Callable and writer.is_valid():
			writer.call(line_path, path, str(values[id]))
		else:
			CandyDialogue.set_field(line_path, path, str(values[id]))


#* Make the map at map_path hold only command type (see "command_map" in the header):
func _set_command(type: String, map_path: Array) -> void:
	var current = CandyDialogue.get_field(line_path, map_path, {})
	if current is Dictionary and current.size() == 1 and current.has(type):
		return
	var commands: Dictionary = {}
	if type != "":
		commands[type] = CandySchemas.default_data(type)
	CandyDialogue.set_field(line_path, map_path, commands)


#* Where this form's field id is stored:
func _path_of(id: String) -> Array:
	for entry in _entries:
		if entry["id"] == id:
			return entry["path"]
	return base_path + [id]


func _spec_of(id: String) -> Dictionary:
	for entry in _entries:
		if entry["id"] == id:
			return entry["spec"]
	return {}


func _read(path: Array) -> Variant:
	var reader = _context.get("field_reader")
	if reader is Callable and reader.is_valid():
		return reader.call(line_path, path)
	return CandyDialogue.get_field(line_path, path)


#* Whether a field's "visible_when" rule lets it show:
#? The rules are in _rule_holds(). Field checks (CandyChecks) use them too.
func _evaluate_visibility(spec: Dictionary, depth: int = 0) -> bool:
	var rule = spec.get("visible_when")
	if not rule is Dictionary or line_path.is_empty():
		return true
	return _rule_holds(rule, depth)


#* Test one rule:
#? unknown_matches: the result for a runtime-only value.
#? own_path, own_value: the field a rule with no "field" tests (checks only).
func _rule_holds(rule: Dictionary, depth: int, unknown_matches: bool = true, own_path: Array = [],
		own_value: String = "") -> bool:
	if rule.has("all"):
		for sub in _sub_rules(rule["all"]):
			if not _rule_holds(sub, depth, unknown_matches, own_path, own_value):
				return false
		return true
	if rule.has("any"):
		for sub in _sub_rules(rule["any"]):
			if _rule_holds(sub, depth, unknown_matches, own_path, own_value):
				return true
		return false
	if rule.get("not") is Dictionary:
		return not _rule_holds(rule["not"], depth, unknown_matches, own_path, own_value)
	if rule.has("types"):			#/ { "types": ["image"] }: the map entry is one of these types, or of no known type
		return CandySchemas.suits_types({"types": rule["types"]}, entry_types)

	var value := ""
	var is_own := false
	if rule.has("provider"):			#/ { "provider": "portrait_kind", "in": ["animation"] } (CandySchemas.register_value_provider())
		value = CandySchemas.provided_value(str(rule["provider"]), _read_sibling).strip_edges()
	else:
		var reference := str(rule.get("field", ""))
		if reference == "":			#/ Checks: the checked field's own value
			if own_path.is_empty():
				return true
			value = own_value.strip_edges()
			is_own = true
		else:
			if not reference.begins_with("../"):
				#% A sibling hidden by its own rule or types matches none:
				var sibling := _spec_of(reference)
				if not sibling.is_empty():
					if not CandySchemas.suits_types(sibling, entry_types):
						return false
					if depth < MAX_RULE_DEPTH and not _evaluate_visibility(sibling, depth + 1):
						return false
			var found = _read(_reference_path(reference))			#/ At this form's level (a repeated entry's siblings); "../" goes up a step
			if found is Dictionary or found is Array:
				found = ""
			value = str(found).strip_edges()

	#% The checked field's own value is tested as written (its checks decide about expressions):
	if not is_own and _is_unknown(value):			#/ Known at runtime only (¢ expression, "null")
		return unknown_matches			#/ Visibility: true, so the field stays shown. Checks: false, so messages only show for values known here
	#? Values compare trimmed and case-insensitively, as Candy DE reads them, numbers as numbers ("0" = "0.0").
	#? {<symbol>} in rule values is the project's symbol.
	var case_sensitive := bool(rule.get("case_sensitive", false))			#/ { "field": "Auto", "equals": "Start", "case_sensitive": true }
	if rule.has("equals"):			#/ { "field": "Type", "equals": "Jump" }
		return _same_value(value, rule["equals"], case_sensitive)
	if rule.has("not_equals"):
		return not _same_value(value, rule["not_equals"], case_sensitive)
	if rule.has("in"):			#/ { "field": "Type", "in": ["Bridge", "Jump"] }
		return _in_values(value, rule["in"], case_sensitive)
	if rule.has("not_in"):
		return not _in_values(value, rule["not_in"], case_sensitive)
	if rule.has("not_empty"):			#/ { "field": "Energy", "not_empty": true }
		return (value != "") == bool(rule["not_empty"])
	if rule.has("greater_than"):			#/ { "field": "Lines", "greater_than": 0 }: non-numbers fail
		return value.is_valid_float() and float(value) > float(str(rule["greater_than"]))
	if rule.has("less_than"):			#/ { "field": "Duration", "less_than": 0 }
		return value.is_valid_float() and float(value) < float(str(rule["less_than"]))
	if rule.has("is_number"):			#/ { "field": "Time", "is_number": true }: whole or not
		return value.is_valid_float() == bool(rule["is_number"])
	if rule.has("begins_with"):			#/ { "field": "Z_Index", "begins_with": ["+", "-"] }
		for start in _rule_values(rule["begins_with"]):
			if value.to_lower().begins_with(start.to_lower()):
				return true
		return false
	if rule.has("ends_with"):			#/ { "field": "File", "ends_with": ".dialogue" }
		for end in _rule_values(rule["ends_with"]):
			if value.to_lower().ends_with(end.to_lower()):
				return true
		return false
	if rule.has("contains"):			#/ { "field": "Wait_Time", "contains": "f=" }
		for part in _rule_values(rule["contains"]):
			if value.to_lower().contains(part.to_lower()):
				return true
		return false
	if rule.has("not_contains"):
		for part in _rule_values(rule["not_contains"]):
			if value.to_lower().contains(part.to_lower()):
				return false
		return true
	return true


#* Path of a rule's or check's "field" - this level, or the one above per "../":
func _reference_path(reference: String) -> Array:
	if not reference.begins_with("../"):
		return _path_of(reference)
	var path := base_path.duplicate()
	while reference.begins_with("../"):
		reference = reference.substr(3)
		if not path.is_empty():
			path.remove_at(path.size() - 1)
	path.append(reference)
	return path


#* A field of this level, for value providers:
func _read_sibling(id: String) -> Variant:
	return _read(_path_of(id))


func _sub_rules(rules: Variant) -> Array:
	var result: Array = []
	if rules is Array:
		for sub in rules:
			if sub is Dictionary:
				result.append(sub)
	return result


#* A rule's value(s) as text ("f=" or ["+", "-"]), with project symbols:
func _rule_values(values: Variant) -> Array:
	var result: Array = []
	if values is Array:
		for item in values:
			result.append(CandyFieldHelpButton.with_symbols(str(item)).strip_edges())
	else:
		result.append(CandyFieldHelpButton.with_symbols(str(values)).strip_edges())
	return result


func _in_values(value: String, values: Variant, case_sensitive: bool = false) -> bool:
	for item in _rule_values(values):
		if _same_value(value, item, case_sensitive):
			return true
	return false


func _same_value(value: String, wanted: Variant, case_sensitive: bool = false) -> bool:
	var other := CandyFieldHelpButton.with_symbols(str(wanted)).strip_edges()
	if value.is_valid_float() and other.is_valid_float():
		return float(value) == float(other)
	if case_sensitive:
		return value == other
	return value.to_lower() == other.to_lower()


#* Whether a value is only known at runtime - a ¢ expression or "null":
func _is_unknown(value: String) -> bool:
	if value == "null":
		return true
	var expression := CandyDropdowns.symbol("expression")
	return expression != "" and value.begins_with(expression)
