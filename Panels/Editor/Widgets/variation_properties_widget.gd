#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationPropertiesWidget
extends CandyFieldsAreaWidget

const VARIATIONS_FIELD := "Variations"

#^ The variation the fields show and write to:
#? Updated only after a field being typed in is committed to the previous one.
var _shown_variation: String = ""


#* Needs the line's Variations, and every property it lists:
func fits_line_type(p_config: Dictionary, line_type: String) -> bool:
	return has_top_field(line_type, VARIATIONS_FIELD) and super.fits_line_type(p_config, line_type)


#* Edits the Group's variation; left out of TTS mode:
func variation_group_config(p_config: Dictionary, refs: Dictionary, mode: String) -> Variant:
	if mode == CandyVariationEditorWidget.MODE_TTS:
		return null
	var result := p_config.duplicate(true)
	result["reference"] = refs["variation"]
	return result


#* A property's default in a new variation:
func _placeholder_value(line_type: String, path: Array) -> Variant:
	var spec := _variations_spec(line_type)
	if spec.is_empty():
		return ""
	return _value_at(CandySchemas.entry_defaults(spec), path)


func _on_configured() -> void:
	super._on_configured()
	var shared := selection()
	if shared != null:
		shared.changed.connect(_on_selection_changed)


func bind_line(line_path: Array) -> void:
	if not CandyDialogue.is_line_path(line_path):
		return
	if line_path != _line_path:
		_release_focus_inside()  #/ Commits to the old line and variation
	_shown_variation = _current_variation()
	super.bind_line(line_path)


func _on_selection_changed(changed_reference: String, _variation_name: String) -> void:
	if changed_reference != reference():
		return
	#? Picking a row doesn't take focus, so a field may hold an edit for the previous variation.
	_release_focus_inside()
	if CandyDialogue.is_line_path(_line_path):
		bind_line(_line_path)


func _current_variation() -> String:
	var shared := selection()
	if shared == null:
		return CandyVariationSelection.DEFAULT_VARIATION
	return shared.get_selected(reference())


#& Fields

#* A line type's variation properties: the Variations entry fields forms may draw:
static func variation_properties(line_type: String, data: Dictionary = {}) -> Array:
	var spec := _variations_spec(line_type, data)
	var result: Array = []
	var fields = spec.get("fields", [])
	if not fields is Array:
		return result
	for field in fields:
		if field is Dictionary and field.has("id") and CandySchemas.in_forms(field):
			result.append(field)
	return result


static func _variations_spec(line_type: String, data: Dictionary = {}) -> Dictionary:
	for spec in CandySchemas.field_specs(line_type, data):
		if spec is Dictionary and str(spec.get("id", "")) == VARIATIONS_FIELD:
			return spec
	return {}


func _all_specs(line_type: String, data: Dictionary) -> Array:
	return variation_properties(line_type, data)


#* Every property - no other widget claims them:
func _catch_all_specs(line_type: String, data: Dictionary) -> Array:
	return _all_specs(line_type, data)


func picker_candidates() -> Array:
	var result: Array = []
	for spec in variation_properties(str(context.get("line_type", ""))):
		var id := str(spec["id"])
		result.append({"id": id, "label": str(spec.get("label", id))})
	return result


#* Properties have no nested fields to leave out:
func picker_children() -> Array:
	return []


func picker_options() -> Dictionary:
	return {
		"title": CandyLocale.t("Variation properties in this area"),
		"catch_all": CandyLocale.t("Every variation property"),
		"catch_all_tooltip": CandyLocale.t("Shows every property of the variation, including ones added to the schema later."),
		"reference_tooltip": CandyLocale.t("Follows the Variation Selector with this reference."),
	}


#* Its fields sit in Variations, so a filter on "Variations/Direction" hides its Direction:
func _schema_base() -> Array:
	return [VARIATIONS_FIELD]


#* The reference already links this to a Variation Selector:
func _follows_field_tree() -> bool:
	return false


#& Data

#* Point the forms at the shown variation's entry instead of the line's top level:
func _form_context(line_type: String) -> Dictionary:
	var result := super._form_context(line_type)
	result["field_reader"] = _read_property
	result["field_writer"] = _write_property
	result["variation_name"] = func() -> String: return _shown_variation	#/ For field checks
	return result


func _variations(line_path: Array) -> Variant:
	if not CandyDialogue.is_line_path(line_path):
		return null
	return CandyDialogue.get_field(line_path, [VARIATIONS_FIELD], null)


func _index_of(variations: Variant, variation: String) -> int:
	if not variations is Array:
		return -1
	for i in variations.size():
		var entry = variations[i]
		if entry is Dictionary and entry.size() > 0 and str(entry.keys()[0]) == variation:
			return i
	return -1


#* Read a property; a missing variation shows the defaults it would be created with:
func _read_property(line_path: Array, path: Array) -> Variant:
	var index := _index_of(_variations(line_path), _shown_variation)
	if index >= 0:
		return CandyDialogue.get_field(line_path,
			[VARIATIONS_FIELD, index, CandyDialogue.ENTRY_VALUE] + path)
	return _value_at(_entry_template(line_path), path)


#* What path leads to inside a variation's data, or "" when nowhere:
static func _value_at(data: Dictionary, path: Array) -> Variant:
	var value: Variant = data
	for step in path:
		if not value is Dictionary:
			return ""
		value = value.get(step, "")
	return value


func _write_property(line_path: Array, path: Array, value: Variant) -> void:
	var variations = _variations(line_path)
	if not variations is Array:
		return
	var index := _index_of(variations, _shown_variation)
	if index >= 0:
		CandyDialogue.set_field(line_path,
			[VARIATIONS_FIELD, index, CandyDialogue.ENTRY_VALUE] + path, value)
		return

	#% Leaving an unchanged field of a missing variation mustn't create it:
	var template := _entry_template(line_path)
	if path.is_empty():
		return
	var current: Variant = _value_at(template, path)
	if typeof(current) == typeof(value) and current == value:
		return
	var container: Variant = _value_at(template, path.slice(0, path.size() - 1))
	if not container is Dictionary:
		return
	container[path[-1]] = value
	CandyDialogue.add_entry(line_path, [VARIATIONS_FIELD], _shown_variation, template)


#* A new Variations entry for the shown variation, from the schema, in its language's direction:
func _entry_template(line_path: Array) -> Dictionary:
	var line := CandyDialogue.line_at(line_path)
	var spec := _variations_spec(CandyDialogue.line_type(line), CandyDialogue.line_data(line))
	if spec.is_empty():
		return {}
	var template := CandySchemas.entry_defaults(spec)
	CandyVariationData.new(CandySettingsDraft.new()).apply_language_direction(template, _shown_variation)
	return template