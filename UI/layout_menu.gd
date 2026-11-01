#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLayoutMenu
extends Node

signal saved(layout_name: String, level: String)
signal loaded(layout_name: String, level: String)

const SAVE_LABEL := "Save Layout..."      #/ translatable
const LOAD_LABEL := "Load Layout"      #/ translatable

var kind := ""
var type_id := ""
var save_label := CandyLocale.t(SAVE_LABEL)
var load_label := CandyLocale.t(LOAD_LABEL)
var save_title := CandyLocale.t("Save Layout")
var empty_label := CandyLocale.t("No saved layouts")
var suggest: Callable
var _capture: Callable
var _apply: Callable
var _fits: Callable

var _load_menu: PopupMenu
var _save_dialog: CandyLayoutSaveDialog
var _save_id := -1
var _layouts: Array = []    #/ Load menu item id -> { "name", "level", "path" }


func setup(p_kind: String, p_type_id: String, capture: Callable, apply: Callable,
		fits: Callable = Callable()) -> void:
	kind = p_kind
	type_id = p_type_id
	_capture = capture
	_apply = apply
	_fits = fits


#* Add both items to a menu:
#? save_id must not clash with the menu's own ids.
func add_items(menu: PopupMenu, save_id: int) -> void:
	_save_id = save_id
	menu.add_item(save_label, save_id)
	if _load_menu == null:
		_load_menu = PopupMenu.new()
		_load_menu.id_pressed.connect(_on_load_pressed)
	menu.add_submenu_node_item(load_label, _load_menu)
	#Ł Re-read the list on each opening, so new files show up:
	if not menu.about_to_popup.is_connected(_fill_load_menu):
		menu.about_to_popup.connect(_fill_load_menu)
	_fill_load_menu()


#* Handle the menu's id_pressed:
func handle_id(id: int) -> bool:
	if id != _save_id:
		return false		#/ Not one of these items
	if _save_dialog == null:
		_save_dialog = CandyLayoutSaveDialog.new()
		#? A child of this Node, which passes no theme on.
		_save_dialog.theme = CandyTheme.theme
		_save_dialog.save_requested.connect(_on_save_requested)
		add_child(_save_dialog)
	var suggestion := {}
	if suggest.is_valid():
		var value = suggest.call()
		if value is Dictionary:
			suggestion = value
	_save_dialog.open(kind, type_id, str(suggestion.get("name", "")), str(suggestion.get("level", "")), save_title)
	return true			#/ One of these items


func _on_save_requested(layout_name: String, level: String) -> void:
	var data = _capture.call()
	if not data is Dictionary:
		data = {}
	if not CandyLayoutLibrary.save(kind, type_id, level, layout_name, data):
		push_error("CandyLayoutMenu: can't save the layout \"%s\"" % layout_name)
		return
	saved.emit(layout_name, level)


#& Load

func _fill_load_menu() -> void:
	if _load_menu == null:
		return
	_load_menu.clear()
	_layouts.clear()
	var layouts := CandyLayoutLibrary.list(kind, type_id)
	var empty_text := empty_label
	if _fits.is_valid() and not layouts.is_empty():
		layouts = layouts.filter(func(layout: Dictionary) -> bool:
			return bool(_fits.call(CandyLayoutLibrary.read(str(layout["path"])))))
		empty_text = CandyLocale.t("No saved layouts fit here")
	if layouts.is_empty():
		_load_menu.add_item(empty_text)
		_load_menu.set_item_disabled(0, true)
		return

	var current_level := ""
	for layout in layouts:
		if layout["level"] != current_level:
			current_level = layout["level"]
			if current_level == CandyLayoutLibrary.LEVEL_USER:
				_load_menu.add_separator(CandyLocale.t("User"))
			else:
				_load_menu.add_separator(CandyLocale.t("Project"))
		_load_menu.add_item(str(layout["name"]), _layouts.size())
		_layouts.append(layout)


func _on_load_pressed(id: int) -> void:
	if id < 0 or id >= _layouts.size():
		return
	var layout: Dictionary = _layouts[id]
	var data := CandyLayoutLibrary.read(str(layout["path"]))
	loaded.emit(str(layout["name"]), str(layout["level"]))
	if _apply.is_valid():
		_apply.call(data.duplicate(true))
