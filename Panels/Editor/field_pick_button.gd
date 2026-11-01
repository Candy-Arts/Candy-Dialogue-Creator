#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldPickButton
extends CandyIconButton

#^ Where a preview widget shows the name of its file - its config's "file_name":
const FILE_NAME_PLACES: Array = ["hidden", "above", "below"]
const DEFAULT_FILE_NAME_PLACE := "hidden"

#^ The top-level field it picks for (its schema id):
var field_id := ""

var _context: Dictionary = {}
var _line_path: Array = []
#^ Never shown - it only builds and answers the field's own dropdown:
var _field: CandyFieldWidget


func _init(p_field_id: String = "", tooltip: String = "") -> void:
	super(&"arrow", &"OptionButton", "v", tooltip)
	field_id = p_field_id
	pressed.connect(_open)


#* Where a preview widget's config shows its file's name (FILE_NAME_PLACES):
static func file_name_place(widget_config: Dictionary) -> String:
	var place := str(widget_config.get("file_name", DEFAULT_FILE_NAME_PLACE))
	if FILE_NAME_PLACES.has(place):
		return place
	return DEFAULT_FILE_NAME_PLACE


#* The label a preview widget shows its file's name in:
static func make_file_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_PASS			#/ For the tooltip: the whole path
	return label


#* Fill a settings dropdown with FILE_NAME_PLACES, labelled above_text and below_text ("Above the portrait"):
static func fill_place_options(button: OptionButton, above_text: String, below_text: String) -> void:
	button.clear()
	for place in FILE_NAME_PLACES:
		match str(place):
			"hidden":
				button.add_item(CandyLocale.t("Hidden"))
			"above":
				button.add_item(above_text)
			"below":
				button.add_item(below_text)
		button.set_item_metadata(button.item_count - 1, place)


#* context: the owning widget's (its line type, and the Editor it's in):
func setup(context: Dictionary) -> void:
	_context = context.duplicate()


func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	disabled = _spec().is_empty()


#* Whether its dropdown is open:
func has_open_menu() -> bool:
	return _field != null and _field._menu != null and _field._menu.visible


#* The field's spec on the bound line, or {} when it has none:
func _spec() -> Dictionary:
	if not CandyDialogue.is_line_path(_line_path):
		return {}
	var line := CandyDialogue.line_at(_line_path)
	return _spec_in(CandyDialogue.line_type(line), CandyDialogue.line_data(line), field_id)


func _spec_in(line_type: String, data: Dictionary, id: String) -> Dictionary:
	for spec in CandySchemas.field_specs(line_type, data):
		if spec is Dictionary and str(spec.get("id", "")) == id:
			return spec
	return {}


#* Open the field's dropdown under this button:
func _open() -> void:
	var spec := _spec()
	if spec.is_empty() or not CandyDropdowns.has_field_dropdown(spec):
		return
	if _field != null:
		_field.queue_free()
	_field = CandyWidgets.instantiate_field(str(spec.get("widget", "line_edit")))
	_field.visible = false
	add_child(_field)
	var field_context := _context.duplicate()
	field_context["line_path"] = _line_path			#/ What dropdown providers read the line from
	_field.field_path = CandySchemas.data_path(spec)
	_field.bind_spec(spec, field_context)
	_field.set_value(str(CandyDialogue.get_field(_line_path, _field.field_path, "")))
	_field.value_committed.connect(_on_value_committed)
	_field.siblings_committed.connect(_on_siblings_committed)
	_field.open_dropdown_under(self)


func _on_value_committed(value: Variant) -> void:
	if _field != null and CandyDialogue.is_line_path(_line_path):
		CandyDialogue.set_field(_line_path, _field.field_path, str(value))


#* The fields beside it that the picked item fills too (a portrait animation's Sprite Frames File):
func _on_siblings_committed(values: Dictionary) -> void:
	if not CandyDialogue.is_line_path(_line_path):
		return
	var line := CandyDialogue.line_at(_line_path)
	for id in values:
		var spec := _spec_in(CandyDialogue.line_type(line), CandyDialogue.line_data(line), str(id))
		if not spec.is_empty():
			CandyDialogue.set_field(_line_path, CandySchemas.data_path(spec), str(values[id]))
