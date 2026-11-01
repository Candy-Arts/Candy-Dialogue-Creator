#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldsAreaWidget
extends CandyAreaWidget

const MAX_COLUMNS := 8
const COLUMN_SEPARATION := 12
const DEFAULT_CLEAR_BUTTON := true
const DEFAULT_RESET_BUTTON := true

var _root: VBoxContainer
var _scroll: ScrollContainer
#^ One child per section - a category, a separator, or the loose fields between them:
var _sections_box: VBoxContainer
var _forms: Array[CandyFieldForm] = []
#^ [{ "node" = Control, "separator" = bool, "forms" = Array, "blocks" = Array }]:
#? A section hides while none of its fields show. "blocks": its parts between separators,
#? separators included, same shape (CandyListSeparators.update_visibility()).
#? A separator has its "id", a category's section its "part" (CandyFilters.category_part()).
var _sections: Array = []
#^ The context the forms share; focus_path is updated in place before a bind:
var _forms_context: Dictionary = {}
var _built_key: String = ""
var _hidden_fields: Dictionary = {}
#^ The categories and separators filters hide:
var _hidden_parts: Dictionary = {}
var _line_path: Array = []
var _settings: CandyFieldsSettings


#* Needs every field it lists; the catch-all fits anywhere:
func fits_line_type(p_config: Dictionary, line_type: String) -> bool:
	var ids := {}
	for spec in _all_specs(line_type, {}):
		ids[str(spec.get("id", ""))] = true
	for id in CandyLineLayouts.field_ids(p_config.get("fields", [])):
		if not ids.has(str(id)):
			return false
	return true


func _on_configured() -> void:
	var shared := field_selection()
	if shared != null and _follows_field_tree():
		shared.changed.connect(_on_field_selection_changed)

	_root = VBoxContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_build_header(_root)

	_sections_box = VBoxContainer.new()
	_sections_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if scrolls():
		_scroll = ScrollContainer.new()
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_root.add_child(_scroll)
		#? Keeps the fields off the scrollbar, only while there is one.
		var gap := MarginContainer.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll.add_child(gap)
		gap.add_child(_sections_box)
		var bar := _scroll.get_v_scroll_bar()
		bar.visibility_changed.connect(func(): _show_gap(gap, bar.visible))
		_show_gap(gap, bar.visible)
		return

	#? No internal scroll - the form's height is the widget's minimum, so the panel scrolls.
	_root.add_child(_sections_box)
	_root.minimum_size_changed.connect(update_minimum_size)


func _show_gap(gap: MarginContainer, shown: bool) -> void:
	if shown:
		gap.theme_type_variation = CandyThemeDefaults.SCROLL_GAP
	else:
		gap.theme_type_variation = &""


func _get_minimum_size() -> Vector2:
	if scrolls() or _root == null:
		return Vector2.ZERO
	return _root.get_combined_minimum_size()


func columns() -> int:
	return clampi(int(config.get("columns", 1)), 1, MAX_COLUMNS)


func bind_line(line_path: Array) -> void:
	if not CandyDialogue.is_line_path(line_path):
		return
	if line_path != _line_path:
		#Ł Commit a field being typed in to the previous line:
		_release_focus_inside()
	_line_path = line_path.duplicate()

	var line := CandyDialogue.line_at(line_path)
	var line_type := CandyDialogue.line_type(line)
	var sections := _sections_for(line_type, CandyDialogue.line_data(line))

	#% Rebuild only when type, fields or columns change, so typing isn't interrupted:
	var key := "%s|%s|%d" % [line_type, str(_keys_of(sections)), columns()]
	if key != _built_key:
		_build_sections(sections, line_type)
		_built_key = key
	_forms_context["focus_path"] = _focus_path(line_path, line_type)
	_forms_context["hidden_children"] = _hidden_children()
	_forms_context["hidden_separators"] = _hidden_parts
	for form in _forms:
		form.bind_line(line_path)
	_update_sections()
	if not scrolls():
		#? Hidden fields and list entries change the height.
		update_minimum_size()


func apply_hidden_fields(hidden_fields: Dictionary) -> void:
	_hidden_fields = hidden_fields
	for form in _forms:
		form.apply_hidden_fields(hidden_fields)


#* Store the hidden parts (applied by the next bind_line()):
func apply_hidden_parts(hidden_parts: Dictionary) -> void:
	_hidden_parts = hidden_parts


#* The fields it lists (or, as the catch-all, those unclaimed), with what's inside, less hidden_children:
func filter_fields(p_config: Dictionary, line_type: String) -> Array:
	var entries = p_config.get("fields", [])
	var ids := CandyLineLayouts.field_ids(entries)
	var specs: Array
	if not entries is Array or entries.is_empty():
		specs = _catch_all_specs(line_type, {})
	else:
		specs = _pick(_all_specs(line_type, {}), ids)
	var left_out = p_config.get("hidden_children", [])
	if not left_out is Array:
		left_out = []
	var base := _schema_base()
	var result: Array = []
	for field in CandySchemas.spec_index(specs):
		if not bool(field["in_forms"]):
			continue
		#? Key from _schema_base() down.
		var key := CandyFieldForm.schema_key(base + Array(str(field["key"]).split("/")))
		field["key"] = key
		var shown := true
		for child in left_out:
			if key == str(child) or key.begins_with(str(child) + "/"):
				shown = false
				break
		if shown:
			result.append(field)
	return result


#* filter_fields() as shown - under categories, with separators, nested fields in "child_order":
func filter_outline(p_config: Dictionary, line_type: String) -> Array:
	var fields := filter_fields(p_config, line_type)
	var child_order = p_config.get("child_order", {})
	if not child_order is Dictionary:
		child_order = {}
	#Ł Where each top-level field starts in fields, by id:
	var tops := {}
	for i in fields.size():
		if int(fields[i]["depth"]) == 0:
			tops[str(fields[i]["id"])] = i

	var result: Array = []
	var entries = p_config.get("fields", [])
	if not entries is Array or entries.is_empty():
		for id in tops:
			_outline_field(fields, int(tops[id]), child_order, 0, result)
		return result
	for entry in entries:
		if CandyListSeparators.is_separator(entry):
			result.append(_outline_part(str(entry), CandyListSeparators.LABEL, 0))
		elif entry is Dictionary:
			var category_name := str(entry.get("name", ""))
			result.append(_outline_part(CandyFilters.category_part(category_name), category_name, 0))
			var inside = entry.get("fields", [])
			if not inside is Array:
				continue
			for id in inside:
				if CandyListSeparators.is_separator(id):
					result.append(_outline_part(str(id), CandyListSeparators.LABEL, 1))
				elif tops.has(str(id)):
					_outline_field(fields, int(tops[str(id)]), child_order, 1, result)
		elif tops.has(str(entry)):
			_outline_field(fields, int(tops[str(entry)]), child_order, 0, result)
	return result


#* Add fields[start] and its children (in "child_order", separators included), extra levels deeper:
func _outline_field(fields: Array, start: int, child_order: Dictionary, extra: int, result: Array) -> int:
	var field: Dictionary = fields[start].duplicate()
	var depth := int(field["depth"])
	field["depth"] = depth + extra
	result.append(field)
	var children := {}    #/ direct child id -> its index in fields
	var ids: Array = []
	var end := start + 1
	while end < fields.size() and int(fields[end]["depth"]) > depth:
		if int(fields[end]["depth"]) == depth + 1:
			children[str(fields[end]["id"])] = end
			ids.append(str(fields[end]["id"]))
		end += 1
	for id in CandyFieldForm.ordered_ids(ids, child_order.get(str(field["key"]))):
		if CandyListSeparators.is_separator(id):
			result.append(_outline_part(id, CandyListSeparators.LABEL, depth + 1 + extra))
		else:
			_outline_field(fields, int(children[id]), child_order, extra, result)
	return end			#/ The index after its last child


func _outline_part(part: String, label: String, depth: int) -> Dictionary:
	return {"part": part, "label": label, "depth": depth, "key": ""}


#* Edit Layout's sample: the forms showing the schema's defaults:
func show_placeholder() -> void:
	if _sections_box == null:
		return
	var line_type := str(context.get("line_type", ""))
	_release_focus_inside()
	_line_path = []
	_build_sections(_sections_for(line_type, {}), line_type)
	#? Whatever line comes next rebuilds the forms.
	_built_key = ""
	_forms_context["field_reader"] = func(_line: Array, path: Array) -> Variant:
		return _placeholder_value(line_type, path)
	#? Drop every edit.
	_forms_context["field_writer"] = func(_line: Array, _path: Array, _value: Variant) -> void:
		pass
	_forms_context["focus_path"] = []
	_forms_context["hidden_children"] = _hidden_children()
	_forms_context["hidden_separators"] = _hidden_parts
	#Ł Bound to no line:
	for form in _forms:
		form.bind_line([])
	_update_sections()
	if not scrolls():
		update_minimum_size()


#* A field's default in a new line:
func _placeholder_value(line_type: String, path: Array) -> Variant:
	var value: Variant = CandySchemas.default_data(line_type)
	for step in path:
		if not value is Dictionary:
			return ""
		value = value.get(step, "")
	return value


#* The "fields" entries - field ids and categories:
func _field_entries() -> Array:
	var entries = config.get("fields", [])
	if entries is Array:
		return entries
	return []


#* The field ids, those of the categories included:
func _field_ids() -> Array:
	return CandyLineLayouts.field_ids(_field_entries())


#* What this widget draws, in display order:
#? [{ "category": index in "fields" (-1 for loose fields), "name", "folded", "separator",
#?   "id" (a separator's), "blocks": [specs, ...], "separators": [ids between the blocks] }]
func _sections_for(line_type: String, data: Dictionary) -> Array:
	var entries := _field_entries()
	if entries.is_empty():
		return [_section(-1, "", false, [_catch_all_specs(line_type, data)], [])]

	var all := _all_specs(line_type, data)
	var sections: Array = []
	var loose: Array = []
	for i in entries.size():
		var entry = entries[i]
		var separator := CandyListSeparators.is_separator(entry)
		#% Consecutive loose fields make one section:
		if not entry is Dictionary and not separator:
			loose.append(str(entry))
			continue
		if not loose.is_empty():
			sections.append(_section(-1, "", false, [_pick(all, loose)], []))
			loose = []
		#% A separator among them is a section of its own:
		if separator:
			sections.append({"category": -1, "name": "", "folded": false, "separator": true,
				"id": str(entry), "blocks": [], "separators": []})
			continue
		var ids = entry.get("fields", [])
		if not ids is Array:
			ids = []
		var separators: Array = []
		sections.append(_section(i, str(entry.get("name", "")),
			CandyVariantFile.to_bool(entry.get("folded", false), false), _blocks(all, ids, separators),
			separators))
	if not loose.is_empty():
		sections.append(_section(-1, "", false, [_pick(all, loose)], []))
	return sections


func _section(category: int, category_name: String, folded: bool, blocks: Array, separators: Array) -> Dictionary:
	return {"category": category, "name": category_name, "folded": folded, "separator": false,
		"id": "", "blocks": blocks, "separators": separators}


#* A category's fields, divided at its separators: [specs, ...]:
func _blocks(all: Array, ids: Array, separators: Array) -> Array:
	var blocks: Array = []
	var block: Array = []
	for id in ids:
		if CandyListSeparators.is_separator(id):
			blocks.append(_pick(all, block))
			block = []
			#Ł Add the separators' ids to separators:
			separators.append(str(id))
		else:
			block.append(id)
	blocks.append(_pick(all, block))
	return blocks


#* The key the forms are rebuilt on - sections, fields and separators:
func _keys_of(sections: Array) -> Array:
	var keys: Array = []
	for section in sections:
		var blocks: Array = []
		for block in section["blocks"]:
			var ids: Array = []
			for spec in block:
				ids.append(str(spec.get("id", "")))
			blocks.append(ids)
		keys.append([section["category"], section["name"], section["separator"], section["id"], blocks,
			section["separators"]])
	return keys


#* Build the sections - category header, fields in columns block by block, or a separator line:
func _build_sections(sections: Array, line_type: String) -> void:
	for child in _sections_box.get_children():
		_sections_box.remove_child(child)
		child.queue_free()
	_forms.clear()
	_sections.clear()

	#? One context for every form, so filters and the current line reach all of them.
	var form_context := _form_context(line_type)
	_forms_context = form_context
	for section in sections:
		if bool(section["separator"]):
			var line := HSeparator.new()
			_sections_box.add_child(line)
			_sections.append({"node": line, "separator": true, "id": section["id"]})
			continue
		var node := VBoxContainer.new()
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_sections_box.add_child(node)
		var header: CandyFoldHeader = null
		if int(section["category"]) >= 0:
			header = CandyFoldHeader.new(str(section["name"]), bool(section["folded"]))
			node.add_child(header)
		var body := VBoxContainer.new()
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.add_child(body)
		var forms: Array = []
		var blocks: Array = []
		var separators: Array = section["separators"]
		var separator_index := 0
		for specs in section["blocks"]:
			if not blocks.is_empty():
				var line := HSeparator.new()
				body.add_child(line)
				blocks.append({"node": line, "separator": true, "id": separators[separator_index]})
				separator_index += 1
			var block_forms: Array = []
			var columns_box := _build_columns(specs, form_context, block_forms)
			body.add_child(columns_box)
			blocks.append({"node": columns_box, "separator": false, "forms": block_forms})
			forms.append_array(block_forms)
		if header != null:
			body.visible = not header.folded
			header.fold_toggled.connect(_on_fold_toggled.bind(int(section["category"]), body))
		var part := ""
		if header != null:
			part = CandyFilters.category_part(str(section["name"]))
		_sections.append({"node": node, "separator": false, "forms": forms, "blocks": blocks, "part": part})


#* One form per column, filled top to bottom, then the next:
func _build_columns(specs: Array, form_context: Dictionary, forms: Array) -> HBoxContainer:
	var columns_box := HBoxContainer.new()
	columns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_box.add_theme_constant_override("separation", COLUMN_SEPARATION)
	var count := columns()
	var per_column := maxi(1, ceili(float(specs.size()) / float(count)))
	for column in count:
		var start := column * per_column
		var chunk: Array = []
		if start < specs.size():
			chunk = specs.slice(start, mini(start + per_column, specs.size()))
		var form := CandyFieldForm.new()
		form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns_box.add_child(form)
		form.build(chunk, [], form_context, _schema_base())
		form.apply_hidden_fields(_hidden_fields)
		#Ł Add to forms and _forms:
		forms.append(form)
		_forms.append(form)
	return columns_box


#* Hide sections and blocks with no field shown, and the parts filters hide:
func _update_sections() -> void:
	for section in _sections:
		if bool(section["separator"]):
			section["hidden"] = _hidden_parts.has(section["id"])
			continue
		for block in section["blocks"]:
			if bool(block["separator"]):
				block["hidden"] = _hidden_parts.has(block["id"])
			else:
				block["shown"] = _any_visible(block["forms"])
		#? Separators only show between shown ones.
		CandyListSeparators.update_visibility(section["blocks"])
		section["shown"] = _any_visible(section["forms"]) and not _hidden_parts.has(section["part"])
	CandyListSeparators.update_visibility(_sections)


func _any_visible(forms: Array) -> bool:
	for form in forms:
		if form.has_visible_fields():
			return true
	return false


#* Fold a category, stored in the config at once:
func _on_fold_toggled(folded: bool, category: int, body: Control) -> void:
	body.visible = not folded
	var entries := _field_entries()
	if category >= entries.size() or not entries[category] is Dictionary:
		return
	var new_config := config.duplicate(true)
	new_config["fields"][category]["folded"] = folded
	store_config(new_config)


#* The data path the Field Tree points at on this line (CandyFieldForm's "focus_path"):
func _focus_path(line_path: Array, line_type: String) -> Variant:
	var shared := field_selection()
	if shared == null or not _follows_field_tree():
		return []
	if not shared.has_selection(reference(), line_type):
		return null			#/ Nothing selected
	var tree_path := shared.get_selected(reference(), line_type)
	if tree_path.is_empty():
		return []			#/ All
	var line := CandyDialogue.line_at(line_path)
	var specs := CandySchemas.field_specs(line_type, CandyDialogue.line_data(line))
	var path = CandyFieldSelection.data_path(line_path, specs, tree_path)
	if path is Array:
		return path
	return []


func _hidden_children() -> Dictionary:
	var result := {}
	var keys = config.get("hidden_children", [])
	if keys is Array:
		for key in keys:
			result[str(key)] = true
	return result


func _on_field_selection_changed(changed_reference: String, line_type: String, _tree_path: Array) -> void:
	if changed_reference != reference() or not CandyDialogue.is_line_path(_line_path):
		return
	if line_type != str(context.get("line_type", "")):
		return
	#? Picking a row doesn't take focus, so a field may still hold an edit.
	_release_focus_inside()
	bind_line(_line_path)


func _release_focus_inside() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var focused := viewport.gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		focused.release_focus()


#& Settings

func has_settings() -> bool:
	return true


func open_settings() -> void:
	if _settings == null:
		_settings = CandyFieldsSettings.new()
		_settings.applied.connect(_on_settings_applied)
		add_child(_settings)
	_settings.open(config, str(picker_options().get("reference_tooltip", "")))


#* Save the settings (rebuilds the line UI):
func _on_settings_applied(changes: Dictionary) -> void:
	var merged := config.duplicate(true)
	for key in changes:
		merged[key] = changes[key]
	if merged != config:
		save_config(merged)


#& Hooks

#* Add controls above the columns (none here):
func _build_header(_parent: VBoxContainer) -> void:
	pass


#* The context shared by this widget's forms:
func _form_context(line_type: String) -> Dictionary:
	var locked := {}
	for key in _locked_keys():
		locked[key] = true
	var child_order = config.get("child_order", {})
	if not child_order is Dictionary:
		child_order = {}
	return {"line_type": line_type, "value_buttons": {
		"clear": bool(config.get("clear_button", DEFAULT_CLEAR_BUTTON)),
		"reset": bool(config.get("reset_button", DEFAULT_RESET_BUTTON)),
	}, "locked_fields": locked, "toggle_lock": _toggle_lock, "child_order": child_order}


func _locked_keys() -> Array:
	var keys: Array = []
	var stored = config.get("locked_fields", [])
	if stored is Array:
		for key in stored:
			keys.append(str(key))
	return keys


#* Lock or unlock a field (right-click menu):
func _toggle_lock(lock_key: String, lock: bool) -> void:
	var keys := _locked_keys()
	if lock and not keys.has(lock_key):
		keys.append(lock_key)
	elif not lock:
		keys.erase(lock_key)
	var new_config := config.duplicate(true)
	new_config["locked_fields"] = keys
	#? Rebuilds the line UI, and the field with it.
	save_config(new_config)


#* Schema path of what the shown fields sit in, [] for the line's own:
#? Filters, locks and hidden children name its fields from there.
func _schema_base() -> Array:
	return []


#* Whether a Field Tree narrows what this widget shows:
func _follows_field_tree() -> bool:
	return true


#* Every spec this widget may draw, in schema order:
func _all_specs(line_type: String, data: Dictionary) -> Array:
	var specs: Array = []
	for spec in CandySchemas.field_specs(line_type, data):
		if spec is Dictionary and CandySchemas.in_forms(spec):
			specs.append(spec)
	return specs


#* What the catch-all draws - everything no other Fields widget claims:
func _catch_all_specs(line_type: String, data: Dictionary) -> Array:
	var placed := {}
	var layouts := line_layouts()
	if layouts != null:
		placed = layouts.placed_fields(line_type)
	var specs: Array = []
	for spec in _all_specs(line_type, data):
		if not placed.has(str(spec.get("id", ""))):
			specs.append(spec)
	return specs


#* The specs of ids, in the picker's order:
func _pick(all: Array, ids: Array) -> Array:
	var by_id := {}
	for spec in all:
		by_id[str(spec.get("id", ""))] = spec
	var specs: Array = []
	for id in ids:
		var key := str(id)
		#% Skip ids no longer in the forms (an older layout):
		if by_id.has(key):
			specs.append(by_id[key])
	return specs


#* What the field picker offers - [{ "id", "label" }], top-level fields only:
func picker_candidates() -> Array:
	var result: Array = []
	for field in CandySchemas.field_index(str(context.get("line_type", ""))):
		if int(field["depth"]) == 0 and bool(field["in_forms"]):
			result.append({"id": field["id"], "label": field["label"]})
	return result


#* The fields the catch-all shows, for the picker to list their children:
func picker_catch_all() -> Array:
	var ids: Array = []
	for spec in _catch_all_specs(str(context.get("line_type", "")), {}):
		ids.append(str(spec.get("id", "")))
	return ids


#* Nested fields the picker can leave out and arrange, in schema order:
func picker_children() -> Array:
	var result: Array = []
	for field in CandySchemas.field_index(str(context.get("line_type", ""))):
		if not bool(field["in_forms"]):
			continue
		var key := str(field["key"])
		var top := key.get_slice("/", 0)
		if int(field["depth"]) > 0 or bool(field["parent"]):
			result.append({"key": key, "label": field["label"], "depth": field["depth"],
				"top": top, "parent": field["parent"]})
	return result


#* Field picker texts, and the reference's tooltip in Options:
func picker_options() -> Dictionary:
	return {
		"title": CandyLocale.t("Fields in this area"),
		"catch_all": CandyLocale.t("Everything not placed in another area"),
		"catch_all_tooltip": CandyLocale.t("Leave this on for one area per tab, so new fields always have somewhere to appear."),
		"reference_tooltip": CandyLocale.t("Follows the Field Tree with this reference."),
	}