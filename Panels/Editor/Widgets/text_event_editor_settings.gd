#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTextEventEditorSettings
extends AcceptDialog

signal applied(config: Dictionary)

#^ Content column width:
#? Wrapping labels need an explicit width, or the dialog opens too tall.
const CONTENT_WIDTH := 428
const LABEL_WIDTH := 100
const MAX_TREE_HEIGHT := 2000

var _tree_height: SpinBox
var _min_size: CandyMinSizeFields


func _init() -> void:
	title = CandyLocale.t("Text Event Editor")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(460, 0)

	var root := VBoxContainer.new()
	root.custom_minimum_size.x = CONTENT_WIDTH
	add_child(root)

	var row := HBoxContainer.new()
	root.add_child(row)
	var label := Label.new()
	label.text = CandyLocale.t("List Height")
	label.custom_minimum_size.x = LABEL_WIDTH
	label.tooltip_text = CandyLocale.t("The height of the list of variation patterns, events and commands, in pixels. The selected event or command is edited below it.")
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	row.add_child(label)
	_tree_height = SpinBox.new()
	_tree_height.min_value = CandyTextEventEditorWidget.MIN_TREE_HEIGHT
	_tree_height.max_value = MAX_TREE_HEIGHT
	_tree_height.step = 10
	_tree_height.suffix = "px"
	_tree_height.tooltip_text = label.tooltip_text
	row.add_child(_tree_height)

	_min_size = CandyMinSizeFields.new()
	root.add_child(_min_size)

	confirmed.connect(_apply)
	canceled.connect(_apply)


func open(config: Dictionary) -> void:
	_tree_height.value = CandyTextEventEditorWidget.tree_height_of(config)
	_min_size.load_config(config)

	#Ł The dialog is reused - drop the previous size:
	reset_size()
	popup_centered()


func _apply() -> void:
	var changes := {"tree_height": int(_tree_height.value)}
	_min_size.write_config(changes)
	applied.emit(changes)
