#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldWidget
extends HBoxContainer

#^ Emitted when an edit is finished (Enter or focus loss), not per keystroke, for undo:
signal value_committed(value: Variant)
#^ After value_committed, when the picked item also writes sibling fields - {field id = value}:
signal siblings_committed(values: Dictionary)

#^ Lock / Unlock item id in the text's menu, well above its own ids:
const LOCK_MENU_ID := 1100
const LOCK_TEXT := "Lock Text Editing"  #/ translatable
const UNLOCK_TEXT := "Unlock Text Editing"  #/ translatable
#^ The dropdown's actions, under its values - ids well above the values' (indices into _menu_values):
const CLEAR_MENU_ID := 1000000
const RESET_MENU_ID := 1000001
#? In capitals, so they read as actions, not values.
const CLEAR_TEXT := "CLEAR"  #/ translatable
const RESET_TEXT := "RESET"  #/ translatable

var spec: Dictionary = {}
var context: Dictionary = {}
#^ Where this field lives in the line's data:
#? e.g. ["Categories", 0, "@entry", "Choices", 2, "@entry", "Label"]
var field_path: Array = []
#^ Its schema path, which locks go by - "Categories/Choices/Label" (CandyFieldForm.schema_key()):
var lock_key := ""
var locked := false

var _dropdown_button: Button
var _menu: PopupMenu
#^ Flat list of values; menu item ids index into it, across submenus:
var _menu_values: Array = []
#^ The "siblings" of each item, by the same ids:
var _menu_siblings: Array = []
#^ The menus being built that hold items with a preview:
var _preview_menus: Array[PopupMenu] = []
#^ CLEAR and RESET at the bottom of the dropdown (add_value_actions()):
var _clear_action := false
var _reset_action := false
#^ The text's own right-click menu, once Lock Text Editing is added to it:
var _lock_menu: PopupMenu


func bind_spec(p_spec: Dictionary, p_context: Dictionary) -> void:
	spec = p_spec
	context = p_context
	_setup_dropdown()
	_on_bound()


func is_read_only() -> bool:
	return bool(spec.get("read_only", false))


#* Whether the value can be typed or picked - not read-only, not locked:
func is_editable() -> bool:
	return not is_read_only() and not locked


#* Lock - no typing, no dropdown (nor its CLEAR and RESET):
func set_locked(value: bool) -> void:
	locked = value
	if _dropdown_button != null:
		_dropdown_button.visible = not locked
	_update_editable()


#* Overridden by subclasses:
func _on_bound() -> void:
	pass


#* Overridden by subclasses - show is_editable() on their controls:
func _update_editable() -> void:
	pass


#* Add Lock / Unlock Text Editing to edit's right-click menu (LineEdit or TextEdit):
func add_lock_menu_item(edit: Control) -> void:
	#% Only when the context has "toggle_lock" - Callable(lock_key: String, lock: bool):
	var toggle = context.get("toggle_lock")
	if is_read_only() or not toggle is Callable:
		return
	#Ł Add it on the menu's first opening (building every field's menu would make big forms take seconds):
	#? gui_input comes before the control handles the event, so the item is there in time.
	edit.gui_input.connect(func(event: InputEvent):
		if _lock_menu == null and _opens_context_menu(event):
			_lock_menu = _menu_of(edit)
			if _lock_menu != null:
				_add_lock_item(_lock_menu, toggle))


func _menu_of(edit: Control) -> PopupMenu:
	if edit is LineEdit:
		return (edit as LineEdit).get_menu()
	if edit is TextEdit:
		return (edit as TextEdit).get_menu()
	return null


#* What a text control opens its right-click menu on:
func _opens_context_menu(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	return event.is_action_pressed("ui_menu")


func _add_lock_item(menu: PopupMenu, toggle: Callable) -> void:
	menu.add_separator()
	menu.add_item(CandyLocale.t(LOCK_TEXT), LOCK_MENU_ID)
	menu.about_to_popup.connect(func():
		var index := menu.get_item_index(LOCK_MENU_ID)
		if locked:
			menu.set_item_text(index, CandyLocale.t(UNLOCK_TEXT))
		else:
			menu.set_item_text(index, CandyLocale.t(LOCK_TEXT)))
	menu.id_pressed.connect(func(id: int):
		if id == LOCK_MENU_ID:
			toggle.call(lock_key, not locked))


func set_value(_value: Variant) -> void:
	pass


func get_value() -> Variant:
	return ""


func commit(value: Variant) -> void:
	value_committed.emit(value)


#* Add CLEAR and RESET at the bottom of the dropdown (not on read-only fields):
#? A field with no values to pick gets a dropdown for them alone.
func add_value_actions(clear: bool, reset: bool) -> void:
	if is_read_only():
		return
	_clear_action = clear
	_reset_action = reset
	if clear or reset:
		_add_dropdown_button()


func _default_value() -> String:
	return CandySchemas.field_default(spec, str(context.get("line_type", "")))


#* Set the field to a value, as a pick:
func _write_picked(value: String) -> void:
	set_value_forced(value)
	commit(value)


#* set_value(), ignoring the "don't interrupt typing" guard (deliberate picks):
func set_value_forced(value: Variant) -> void:
	set_value(value)


#& Dropdown

func _dropdown_config() -> Dictionary:
	var config = spec.get("dropdown", {})
	if config is Dictionary:
		return config
	return {}


func _setup_dropdown() -> void:
	if CandyDropdowns.has_field_dropdown(spec):
		_add_dropdown_button()


func _add_dropdown_button() -> void:
	if _dropdown_button != null or is_read_only():
		return
	_dropdown_button = CandyIconButton.new(&"arrow", &"OptionButton", "v", CandyLocale.t("Pick a value"))
	#? Beside the first line of a multi-line field, not stretched along it.
	_dropdown_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_dropdown_button.visible = not locked
	_dropdown_button.pressed.connect(_open_dropdown)
	add_child(_dropdown_button)
	move_child(_dropdown_button, 0)  #/ Left of the editing control


#* Open the dropdown under another control than its own button (CandyFieldPickButton):
func open_dropdown_under(anchor: Control) -> void:
	_open_dropdown(anchor)


#* Open the dropdown, rebuilt on every press so computed lists are current:
func _open_dropdown(anchor_control: Control = null) -> void:
	if anchor_control == null:
		anchor_control = _dropdown_button
	if _menu != null:
		_menu.queue_free()
		_menu = null
	_menu_values.clear()
	_menu_siblings.clear()
	_preview_menus.clear()

	#? "No override (null)" comes first when the default is "null".
	var items: Array = []
	if CandyDropdowns.has_field_dropdown(spec):
		items = CandyDropdowns.field_items(spec, _menu_context())
	if items.is_empty() and not _clear_action and not _reset_action:
		return

	_menu = _build_menu(items)
	_add_action_items(_menu)
	add_child(_menu)
	if not _preview_menus.is_empty():
		var preview := CandyMediaPreview.new()
		_menu.add_child(preview)
		for menu in _preview_menus:
			preview.watch(menu)
	var anchor := Rect2i(Vector2i(anchor_control.get_screen_position()), Vector2i(anchor_control.size))
	CandyPopups.popup_at(_menu, anchor, anchor_control)


func _menu_context() -> Dictionary:
	var result := context.duplicate()
	result["field_path"] = field_path
	result["spec"] = spec
	return result


func _build_menu(items: Array) -> PopupMenu:
	var menu := PopupMenu.new()
	menu.id_pressed.connect(_on_menu_id_pressed)

	for raw_item in items:
		var item := CandyDropdowns.normalize_item(raw_item)
		if item["separator"]:
			menu.add_separator(item["label"])
			continue

		var children: Array = item["items"]
		#% A provider submenu computes its children; left out when it has none:
		if children.is_empty() and item["config"] is Dictionary and item["config"].has("provider"):
			children = CandyDropdowns.get_items(item["config"], _menu_context())
			if children.is_empty():
				continue

		if not children.is_empty():
			#? Opens on hover.
			menu.add_submenu_node_item(item["label"], _build_menu(children))
			continue

		var id := _menu_values.size()
		_menu_values.append(item["value"])
		var siblings: Dictionary = {}
		if item["config"] is Dictionary and item["config"].get("siblings") is Dictionary:
			siblings = item["config"]["siblings"]
		_menu_siblings.append(siblings)
		#? Label, plus the value it writes when different - "On (1)".
		menu.add_item(item["text"], id)
		#? By index - a submenu's own id may be the same as an item's.
		var index := menu.item_count - 1
		if item["tooltip"] != "":
			menu.set_item_tooltip(index, item["tooltip"])
		if item["config"] is Dictionary and item["config"].get("preview") is Dictionary:
			menu.set_item_metadata(index, item["config"]["preview"])
			if not _preview_menus.has(menu):
				_preview_menus.append(menu)

	return menu


#* Add CLEAR and RESET under the values, with a line between them:
func _add_action_items(menu: PopupMenu) -> void:
	if not _clear_action and not _reset_action:
		return
	if menu.item_count > 0:
		menu.add_separator()
	if _clear_action:
		menu.add_item(CandyLocale.t(CLEAR_TEXT), CLEAR_MENU_ID)
		menu.set_item_tooltip(menu.item_count - 1, CandyLocale.t("Empties the field."))
	if _reset_action:
		#? The default may come from the settings, so it's read as the menu opens.
		var default_value := _default_value()
		var shown := default_value
		if shown == "":
			shown = CandyLocale.t("empty")
		menu.add_item("%s (%s)" % [CandyLocale.t(RESET_TEXT), shown], RESET_MENU_ID)
		menu.set_item_tooltip(menu.item_count - 1, CandyLocale.t("Puts back the field's default value."))


#* Write the picked item, and its "siblings":
func _on_menu_id_pressed(id: int) -> void:
	if id == CLEAR_MENU_ID:
		_write_picked("")
		return
	if id == RESET_MENU_ID:
		_write_picked(_default_value())
		return
	if id < 0 or id >= _menu_values.size():
		return
	var value := str(_menu_values[id])
	var siblings: Dictionary = _menu_siblings[id]
	var config := _dropdown_config()
	#? "null" is the whole value, never one more list entry.
	if str(config.get("pick", "replace")) == "append" and value != CandyDropdowns.NOT_SET_VALUE:
		value = _appended(str(get_value()), value, str(config.get("join", ", ")))
	set_value_forced(value)
	#? The value and its siblings are one undo step.
	CandyDialogue.begin_step()
	commit(value)
	if not siblings.is_empty():
		siblings_committed.emit(siblings)
	CandyDialogue.end_step()


#* current with picked added at the end, joined by join (not twice):
func _appended(current: String, picked: String, join: String) -> String:
	var text := current.strip_edges()
	if text == "":
		return picked
	var divider := join.strip_edges()
	if divider == "":
		divider = join
	for part in text.split(divider, false):
		if part.strip_edges() == picked:
			return text
	return text + join + picked