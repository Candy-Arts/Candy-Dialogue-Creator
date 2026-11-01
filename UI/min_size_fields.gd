#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyMinSizeFields
extends VBoxContainer

const MAX_SIZE := 4096
const FIELD_WIDTH := 120
const LABEL_WIDTH := 80
#^ An Area's size limits, kept in its config:
const KEYS: Array[String] = ["min_width", "min_height", "max_width", "max_height"]

#^ By KEYS:
var _fields: Dictionary = {}


func _init() -> void:
	add_child(HSeparator.new())
	_add_heading(CandyLocale.t("Minimum Size"))
	_fields["min_width"] = _add_row(CandyLocale.t("Width"), CandyLocale.t("The least width this area gets, in pixels."))
	_fields["min_height"] = _add_row(CandyLocale.t("Height"), CandyLocale.t("The least height this area gets, in pixels."))
	_add_note(CandyLocale.t("0 means no minimum. The area still grows to fit what it shows."))

	_add_heading(CandyLocale.t("Maximum Size"))
	_fields["max_width"] = _add_row(CandyLocale.t("Width"),
		CandyLocale.t("The most width this area takes, in pixels. The area beside it gets the rest."))
	_fields["max_height"] = _add_row(CandyLocale.t("Height"),
		CandyLocale.t("The most height this area takes, in pixels. The area beside it gets the rest."))
	_add_note(CandyLocale.t("0 means no maximum. The minimum size, and what the area shows, still win."))


func _add_heading(text: String) -> void:
	var heading := Label.new()
	heading.text = text
	heading.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	add_child(heading)


func _add_note(text: String) -> void:
	var note := Label.new()
	note.text = text
	note.theme_type_variation = CandyThemeDefaults.NOTE
	add_child(note)


func _add_row(label_text: String, tooltip: String) -> SpinBox:
	var row := HBoxContainer.new()
	add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	row.add_child(label)
	var field := SpinBox.new()
	field.min_value = 0
	field.max_value = MAX_SIZE
	field.step = 1
	field.suffix = CandyLocale.t("px")
	field.select_all_on_focus = true
	field.custom_minimum_size.x = FIELD_WIDTH
	field.tooltip_text = tooltip
	row.add_child(field)
	return field


#* The fields' line edits, for a dialog to confirm on Enter:
func line_edits() -> Array[LineEdit]:
	var result: Array[LineEdit] = []
	for key in KEYS:
		result.append((_fields[key] as SpinBox).get_line_edit())
	return result


#* Show size limits ({ KEYS: int }, missing ones 0):
func set_limits(limits: Dictionary) -> void:
	for key in KEYS:
		(_fields[key] as SpinBox).set_value_no_signal(maxi(0, int(limits.get(key, 0))))


#* The typed size limits, { KEYS: int }:
func get_limits() -> Dictionary:
	var result := {}
	for key in KEYS:
		var field: SpinBox = _fields[key]
		field.apply()			#/ Count typed values even without Enter
		result[key] = int(field.value)
	return result


#* Show a widget's size limits from its area's config:
func load_config(config: Dictionary) -> void:
	set_limits(limits_of(config))


#* Add the typed size limits to the changes merged into the area's config:
func write_config(changes: Dictionary) -> void:
	changes.merge(get_limits(), true)


#* An Area's size limits from its config, { KEYS: int }:
static func limits_of(config: Dictionary) -> Dictionary:
	var result := {}
	for key in KEYS:
		result[key] = maxi(0, int(config.get(key, 0)))
	return result


#* An Area's minimum size from its config ("min_width", "min_height"):
static func of_config(config: Dictionary) -> Vector2i:
	return Vector2i(maxi(0, int(config.get("min_width", 0))), maxi(0, int(config.get("min_height", 0))))


#* An Area's maximum size from its config ("max_width", "max_height"; 0: none):
static func max_of_config(config: Dictionary) -> Vector2i:
	return Vector2i(maxi(0, int(config.get("max_width", 0))), maxi(0, int(config.get("max_height", 0))))
