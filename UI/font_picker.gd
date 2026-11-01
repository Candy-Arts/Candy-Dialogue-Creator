#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFontPicker
extends HBoxContainer

signal font_changed(file_name: String)

var _list: OptionButton
#^ The picked file name ("" for the default):
var _font := ""
#^ The label of the "" item:
var _default_label := ""


func _init(default_label: String = "") -> void:
	_default_label = default_label
	if _default_label == "":
		_default_label = CandyLocale.t("Default", "font")

	_list = OptionButton.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.fit_to_longest_item = false
	_list.item_selected.connect(_on_item_selected)
	#? Read again as it opens, so a font just dropped in the folder is there.
	_list.get_popup().about_to_popup.connect(_fill)
	add_child(_list)

	var folder := Button.new()
	folder.text = CandyLocale.t("Open Folder")
	folder.tooltip_text = CandyLocale.t("Opens the fonts folder. Put font files there (.ttf, .otf, .woff, .woff2), then pick them in this list.")
	folder.pressed.connect(func(): OS.shell_open(CandyTheme.user_fonts_folder()))
	add_child(folder)

	_fill()


func set_font(file_name: String) -> void:
	_font = file_name
	_fill()


func get_font() -> String:
	return _font


func set_tooltip(text: String) -> void:
	_list.tooltip_text = text


#* List the default, then the font files (and the picked one, if its file is gone):
func _fill() -> void:
	_list.clear()
	_list.add_item(_default_label)
	_list.set_item_metadata(0, "")
	_list.select(0)
	var files: PackedStringArray = CandyTheme.font_files()
	for file_name in files:
		_add_item(file_name, file_name)
	if _font != "" and not files.has(_font):
		_add_item(CandyLocale.t("%s (not in the fonts folder)") % _font, _font)


func _add_item(text: String, file_name: String) -> void:
	_list.add_item(text)
	var index := _list.item_count - 1
	_list.set_item_metadata(index, file_name)
	if file_name == _font:
		_list.select(index)


func _on_item_selected(index: int) -> void:
	_font = str(_list.get_item_metadata(index))
	font_changed.emit(_font)
