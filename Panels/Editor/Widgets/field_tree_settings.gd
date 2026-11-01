#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldTreeSettings
extends AcceptDialog

signal applied(config: Dictionary)

const BUTTON_POSITIONS := ["top", "bottom"]

var _reference: LineEdit
var _buttons: OptionButton
var _order_box: VBoxContainer
var _order_list: ItemList
#^ The buttons' keys ("Categories/Choices"), in the list's order:
var _order: Array = []
var _min_size: CandyMinSizeFields


func _init() -> void:
	title = CandyLocale.t("Field Tree")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(360, 0)

	var root := VBoxContainer.new()
	add_child(root)

	var reference_row := HBoxContainer.new()
	root.add_child(reference_row)
	var reference_label := Label.new()
	reference_label.text = CandyLocale.t("Reference")
	reference_label.custom_minimum_size.x = 100
	reference_label.tooltip_text = CandyLocale.t("Fields widgets with this reference show the field picked here.")
	reference_label.mouse_filter = Control.MOUSE_FILTER_PASS
	reference_row.add_child(reference_label)
	_reference = LineEdit.new()
	_reference.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reference_row.add_child(_reference)

	var buttons_row := HBoxContainer.new()
	root.add_child(buttons_row)
	var buttons_label := Label.new()
	buttons_label.text = CandyLocale.t("Add buttons")
	buttons_label.custom_minimum_size.x = 100
	buttons_row.add_child(buttons_label)
	_buttons = OptionButton.new()
	_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buttons.add_item(CandyLocale.t("Above the list"))
	_buttons.add_item(CandyLocale.t("Below the list"))
	CandyPopups.attach_button_popup(_buttons)
	buttons_row.add_child(_buttons)

	_order_box = VBoxContainer.new()
	root.add_child(_order_box)
	var order_label := Label.new()
	order_label.text = CandyLocale.t("Button order")
	_order_box.add_child(order_label)
	_order_list = ItemList.new()
	_order_list.auto_height = true
	_order_list.tooltip_text = CandyLocale.t("Drag the buttons into the order they show in.")
	CandyListSelection.enable_reorder(_order_list, func(indices: Array, slot: int):
		var moved := CandyListSelection.move_to(_order, indices, slot)
		_fill_order(_order_list.get_meta(&"labels", {}))
		CandyListSelection.select_indices(_order_list, moved))
	_order_box.add_child(_order_list)
	var order_note := Label.new()
	order_note.text = CandyLocale.t("Drag to reorder.")
	order_note.theme_type_variation = CandyThemeDefaults.NOTE
	_order_box.add_child(order_note)

	_min_size = CandyMinSizeFields.new()
	root.add_child(_min_size)

	confirmed.connect(_apply)
	canceled.connect(_apply)


#* Open the dialog:
#? buttons: the widget's add buttons, in order ([{ "key", "label" }]).
func open(config: Dictionary, buttons: Array = []) -> void:
	_order.clear()
	var labels := {}
	for button in buttons:
		_order.append(str(button["key"]))
		labels[str(button["key"])] = str(button["label"])
	_fill_order(labels)
	#? A single button has no order to choose.
	_order_box.visible = _order.size() > 1
	_reference.text = str(config.get("reference", CandyVariationSelection.DEFAULT_REFERENCE))
	var position_index := BUTTON_POSITIONS.find(
		str(config.get("buttons", CandyFieldTreeWidget.DEFAULT_BUTTONS)))
	_buttons.select(maxi(0, position_index))
	_min_size.load_config(config)
	reset_size()
	popup_centered()


func _apply() -> void:
	var reference := _reference.text.strip_edges()
	if reference == "":
		reference = CandyVariationSelection.DEFAULT_REFERENCE
	var changes := {
		"reference": reference,
		"buttons": BUTTON_POSITIONS[maxi(0, _buttons.selected)],
	}
	if _order.size() > 1:
		changes["button_order"] = _order.duplicate()
	_min_size.write_config(changes)
	applied.emit(changes)


func _fill_order(labels: Dictionary) -> void:
	_order_list.set_meta(&"labels", labels)
	_order_list.clear()
	for key in _order:
		_order_list.add_item(str(labels.get(key, key)))
