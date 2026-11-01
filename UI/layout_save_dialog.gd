#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLayoutSaveDialog
extends ConfirmationDialog

#^ Emitted with a valid name. The owner writes the file:
signal save_requested(layout_name: String, level: String)

#^ Level last picked, offered by the next dialog:
static var _last_level := CandyLayoutLibrary.LEVEL_PROJECT

const LIST_HEIGHT := 160
const LEVEL_TEXTS := {
	CandyLayoutLibrary.LEVEL_PROJECT: "Project",      #/ translatable
	CandyLayoutLibrary.LEVEL_USER: "User",      #/ translatable
}

var _list: ItemList
var _empty_note: Label
var _delete_button: Button
var _edit: LineEdit
var _user_level: CheckButton
var _message: Label
var _kind := ""
var _type_id := ""
#^ Saved layouts by list index - { "name", "level", "path" }:
var _layouts: Array = []


func _init() -> void:
	title = CandyLocale.t("Save Layout")
	ok_button_text = CandyLocale.t("Save")
	min_size = Vector2i(380, 0)
	dialog_hide_on_ok = false  #/ Closed once the name validates

	var box := VBoxContainer.new()
	add_child(box)

	var list_label := Label.new()
	list_label.text = CandyLocale.t("Saved layouts")
	box.add_child(list_label)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(340, LIST_HEIGHT)
	_list.item_selected.connect(_on_layout_picked)
	box.add_child(_list)

	_empty_note = Label.new()
	_empty_note.text = CandyLocale.t("None yet.")
	_empty_note.theme_type_variation = CandyThemeDefaults.NOTE
	box.add_child(_empty_note)

	_delete_button = Button.new()
	_delete_button.text = CandyLocale.t("Delete")
	_delete_button.tooltip_text = CandyLocale.t("Delete the layout picked above.")
	_delete_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_delete_button.pressed.connect(_on_delete_pressed)
	box.add_child(_delete_button)

	box.add_child(HSeparator.new())

	var name_label := Label.new()
	name_label.text = CandyLocale.t("Name")
	box.add_child(name_label)

	_edit = LineEdit.new()
	_edit.custom_minimum_size.x = 340
	_edit.text_changed.connect(func(_text: String): _on_target_changed())
	box.add_child(_edit)

	_user_level = CheckButton.new()
	_user_level.text = CandyLocale.t("User level (every project)")
	_user_level.tooltip_text = CandyLocale.t("Off saves it for this project only.")
	_user_level.toggled.connect(func(_on: bool): _on_target_changed())
	box.add_child(_user_level)

	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.x = 340
	box.add_child(_message)

	register_text_enter(_edit)
	confirmed.connect(_on_confirmed)


#* Open the dialog:
#? level: the starting level, "" for the last picked. dialog_title: e.g. "Save Colors".
func open(kind: String, type_id: String, suggestion: String = "", level: String = "",
		dialog_title: String = "Save Layout") -> void:
	title = dialog_title
	_kind = kind
	_type_id = type_id
	_fill_list()
	_edit.text = suggestion
	if level == "":
		level = _last_level
	_user_level.set_pressed_no_signal(level == CandyLayoutLibrary.LEVEL_USER)
	_on_target_changed()
	reset_size()
	popup_centered()
	_edit.grab_focus()
	_edit.select_all()


func _level() -> String:
	if _user_level.button_pressed:
		return CandyLayoutLibrary.LEVEL_USER
	return CandyLayoutLibrary.LEVEL_PROJECT


func _key(layout_name: String, level: String) -> String:
	return "%s|%s" % [level, layout_name]


#& Saved layouts

func _fill_list() -> void:
	_list.clear()
	_layouts = CandyLayoutLibrary.list(_kind, _type_id)
	for layout in _layouts:
		var index := _list.add_item("%s  (%s)" % [layout["name"], CandyLocale.t(str(LEVEL_TEXTS.get(layout["level"], layout["level"])))])
		_list.set_item_tooltip(index, CandyLocale.t("Pick it to replace it, or to delete it."))
	_list.visible = not _layouts.is_empty()
	_empty_note.visible = _layouts.is_empty()
	_delete_button.visible = not _layouts.is_empty()
	_delete_button.disabled = true


#* Make a picked layout the one Save replaces:
func _on_layout_picked(index: int) -> void:
	var layout: Dictionary = _layouts[index]
	_edit.text = str(layout["name"])
	_user_level.set_pressed_no_signal(layout["level"] == CandyLayoutLibrary.LEVEL_USER)
	_on_target_changed()


func _picked() -> Dictionary:
	var selected := _list.get_selected_items()
	if selected.is_empty():
		return {}
	return _layouts[selected[0]]


func _on_delete_pressed() -> void:
	var layout := _picked()
	if layout.is_empty():
		return
	var question := CandyLocale.t("Delete the layout \"%s\"?\nIt will be gone from this project.") % layout["name"]
	if layout["level"] == CandyLayoutLibrary.LEVEL_USER:
		question = CandyLocale.t("Delete the layout \"%s\"?\nIt will be gone from every project of this user.") % layout["name"]
	CandyConfirmPrompt.ask(self, CandyLocale.t("Delete Layout"), question, CandyLocale.t("Delete"),
		func():
			if not CandyLayoutLibrary.delete(_kind, _type_id, str(layout["level"]), str(layout["name"])):
				_message.theme_type_variation = CandyThemeDefaults.ERROR
				_message.text = CandyLocale.t("Can't delete \"%s\".") % layout["name"]
				return
			_fill_list()
			_on_target_changed())


#& Name and level

#* Name or level changed - select the layout they name, if any:
func _on_target_changed() -> void:
	_message.text = ""
	_list.deselect_all()
	var target := _key(_edit.text.strip_edges(), _level())
	for i in _layouts.size():
		if _key(str(_layouts[i]["name"]), str(_layouts[i]["level"])) == target:
			_list.select(i)
			_list.ensure_current_is_visible()
	_delete_button.disabled = _list.get_selected_items().is_empty()


func _on_confirmed() -> void:
	var layout_name := _edit.text.strip_edges()
	var problem := CandyProfiles.validate_name(layout_name)
	if problem != "":
		_message.theme_type_variation = CandyThemeDefaults.ERROR
		_message.text = problem
		return

	var level := _level()
	if not CandyLayoutLibrary.exists(_kind, _type_id, level, layout_name):
		_save(layout_name, level)
		return
	var question := CandyLocale.t("Replace the layout \"%s\"?\nThe one saved for this project will be overwritten.") % layout_name
	if level == CandyLayoutLibrary.LEVEL_USER:
		question = CandyLocale.t("Replace the layout \"%s\"?\nThe one saved for every project of this user will be overwritten.") % layout_name
	CandyConfirmPrompt.ask(self, CandyLocale.t("Replace Layout"), question, CandyLocale.t("Replace"),
		func(): _save(layout_name, level))


func _save(layout_name: String, level: String) -> void:
	_last_level = level
	hide()
	save_requested.emit(layout_name, level)
