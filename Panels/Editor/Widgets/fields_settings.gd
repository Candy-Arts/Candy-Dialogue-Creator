#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldsSettings
extends AcceptDialog

#^ Only the keys this dialog edits; the widget merges them into its config:
signal applied(changes: Dictionary)

const LABEL_WIDTH := 100

var _reference_label: Label
var _reference: LineEdit
var _clear: CheckBox
var _reset: CheckBox
var _min_size: CandyMinSizeFields


func _init() -> void:
	title = CandyLocale.t("Fields")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(360, 0)

	var root := VBoxContainer.new()
	add_child(root)

	var reference_row := HBoxContainer.new()
	root.add_child(reference_row)
	_reference_label = Label.new()
	_reference_label.text = CandyLocale.t("Reference")
	_reference_label.custom_minimum_size.x = LABEL_WIDTH
	_reference_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	reference_row.add_child(_reference_label)
	_reference = LineEdit.new()
	_reference.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reference_row.add_child(_reference)

	root.add_child(HSeparator.new())

	_clear = CheckBox.new()
	_clear.text = CandyLocale.t("CLEAR in drop-downs")
	_clear.tooltip_text = CandyLocale.t("CLEAR, at the bottom of each field's drop-down, empties the field. Fields with no values to pick get a drop-down for it.")
	root.add_child(_clear)

	_reset = CheckBox.new()
	_reset.text = CandyLocale.t("RESET in drop-downs")
	_reset.tooltip_text = CandyLocale.t("RESET, at the bottom of each field's drop-down, puts back the field's default value, shown beside it. Fields with no values to pick get a drop-down for it.")
	root.add_child(_reset)

	_min_size = CandyMinSizeFields.new()
	root.add_child(_min_size)

	confirmed.connect(_apply)
	canceled.connect(_apply)


#* Open the dialog:
func open(config: Dictionary, reference_tooltip: String) -> void:
	_reference.text = str(config.get("reference", CandyVariationSelection.DEFAULT_REFERENCE))
	_reference_label.tooltip_text = reference_tooltip
	_reference.tooltip_text = reference_tooltip
	_clear.button_pressed = bool(config.get("clear_button", CandyFieldsAreaWidget.DEFAULT_CLEAR_BUTTON))
	_reset.button_pressed = bool(config.get("reset_button", CandyFieldsAreaWidget.DEFAULT_RESET_BUTTON))
	_min_size.load_config(config)
	reset_size()
	popup_centered()


func _apply() -> void:
	var reference := _reference.text.strip_edges()
	if reference == "":
		reference = CandyVariationSelection.DEFAULT_REFERENCE
	var changes := {
		"reference": reference,
		"clear_button": _clear.button_pressed,
		"reset_button": _reset.button_pressed,
	}
	_min_size.write_config(changes)
	applied.emit(changes)
