#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPortraitPreviewSettings
extends AcceptDialog

#^ Only the keys this dialog edits; the widget merges them into its config:
signal applied(changes: Dictionary)

const LABEL_WIDTH := 130
const BUTTON_LABELS := {
	"hidden": "Hidden",  #/ translatable
	"reveal": "Over the portrait, while the mouse is over it",  #/ translatable
	"above": "In a row above the portrait",  #/ translatable
	"below": "In a row below the portrait",  #/ translatable
	"left": "In a column on its left",  #/ translatable
	"right": "In a column on its right",  #/ translatable
}
const IMAGE_FILTERS := ["*.png, *.jpg, *.jpeg, *.webp, *.svg, *.bmp, *.tga ; Images"]

var _color: ColorPickerButton
var _texture: LineEdit
var _file_dialog: FileDialog
var _hover: CheckBox
var _buttons: OptionButton
var _file_name: OptionButton
#^ The buttons' order, dragged into place:
var _order_list: ItemList
var _order: Array = []
var _min_size: CandyMinSizeFields


func _init() -> void:
	title = CandyLocale.t("Portrait Preview")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(480, 0)

	var root := VBoxContainer.new()
	add_child(root)

	var color_row := _row(root, CandyLocale.t("Background color"), CandyLocale.t("Shown behind the portrait when there's no background texture."))
	_color = ColorPickerButton.new()
	_color.edit_alpha = true
	_color.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_row.add_child(_color)

	var texture_row := _row(root, CandyLocale.t("Background texture"), CandyLocale.t("An image on disk, shown behind the portrait instead of the color. Empty for none."))
	_texture = LineEdit.new()
	_texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texture.placeholder_text = CandyLocale.t("None")
	texture_row.add_child(_texture)
	var browse := Button.new()
	browse.text = "..."
	browse.tooltip_text = CandyLocale.t("Pick an image")
	browse.pressed.connect(_browse)
	texture_row.add_child(browse)

	_hover = CheckBox.new()
	_hover.text = CandyLocale.t("Play animated portraits while the mouse is over them")
	_hover.tooltip_text = CandyLocale.t("Off: they play when the line's Play Portrait is 1, as in game.")
	root.add_child(_hover)

	var buttons_row := _row(root, CandyLocale.t("Buttons"), CandyLocale.t("Play / pause, stop, and the background color."))
	_buttons = OptionButton.new()
	_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for place in CandyPortraitPreviewWidget.BUTTON_PLACES:
		_buttons.add_item(CandyLocale.t(str(BUTTON_LABELS[place])))
		_buttons.set_item_metadata(_buttons.item_count - 1, place)
	buttons_row.add_child(_buttons)

	var order_row := _row(root, CandyLocale.t("Button order"), CandyLocale.t("Drag the buttons into the order they're shown in."))
	_order_list = ItemList.new()
	_order_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_order_list.auto_height = true
	_order_list.tooltip_text = CandyLocale.t("Drag the buttons into the order they're shown in.")
	CandyListSelection.enable_reorder(_order_list, func(indices: Array, slot: int):
		var moved := CandyListSelection.move_to(_order, indices, slot)
		_refresh_order()
		CandyListSelection.select_indices(_order_list, moved))
	order_row.add_child(_order_list)

	var file_row := _row(root, CandyLocale.t("File name"), CandyLocale.t("The name of the portrait's file (its whole path in the tooltip)."))
	_file_name = OptionButton.new()
	_file_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CandyFieldPickButton.fill_place_options(_file_name, CandyLocale.t("Above the portrait"),
		CandyLocale.t("Below the portrait"))
	file_row.add_child(_file_name)

	var note := Label.new()
	note.text = CandyLocale.t("An actor's or role's own background, from Settings > UI > Portrait Backgrounds, is shown instead of these.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 450
	note.theme_type_variation = CandyThemeDefaults.NOTE
	root.add_child(note)

	_min_size = CandyMinSizeFields.new()
	root.add_child(_min_size)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(IMAGE_FILTERS)
	_file_dialog.file_selected.connect(func(path: String): _texture.text = path)
	add_child(_file_dialog)

	confirmed.connect(_apply)
	canceled.connect(_apply)


func _row(root: VBoxContainer, label_text: String, tooltip: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	root.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.tooltip_text = tooltip
	label.custom_minimum_size.x = LABEL_WIDTH
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	row.add_child(label)
	return row


func _refresh_order() -> void:
	_order_list.clear()
	for id in _order:
		_order_list.add_item(CandyLocale.t(str(CandyPortraitPreviewWidget.BUTTON_TITLES[id])))


func _browse() -> void:
	var current := _texture.text.strip_edges()
	if current != "":
		_file_dialog.current_path = current
	_file_dialog.popup_centered_ratio(0.6)


func open(config: Dictionary) -> void:
	_color.color = CandySpeechEditorSettings.to_color(config.get("background_color", ""),
		CandyPortraitPreviewWidget.DEFAULT_BACKGROUND)
	_texture.text = str(config.get("background_texture", ""))
	_hover.button_pressed = bool(config.get("play_on_hover", false))
	var place := str(config.get("buttons", CandyPortraitPreviewWidget.DEFAULT_BUTTONS))
	var index := CandyPortraitPreviewWidget.BUTTON_PLACES.find(place)
	_buttons.select(maxi(index, 0))
	_order = CandyPortraitPreviewWidget.button_order(config)
	_refresh_order()
	_file_name.select(maxi(CandyFieldPickButton.FILE_NAME_PLACES.find(CandyFieldPickButton.file_name_place(config)), 0))
	_min_size.load_config(config)
	reset_size()
	popup_centered()


func _apply() -> void:
	var changes := {
		"background_color": var_to_str(_color.color),
		"background_texture": _texture.text.strip_edges(),
		"play_on_hover": _hover.button_pressed,
		"buttons": str(_buttons.get_item_metadata(_buttons.selected)),
		"button_order": _order.duplicate(),
		"file_name": str(_file_name.get_item_metadata(maxi(_file_name.selected, 0))),
	}
	_min_size.write_config(changes)
	applied.emit(changes)
