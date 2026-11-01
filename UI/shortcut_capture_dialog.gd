#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyShortcutCaptureDialog
extends AcceptDialog

const NO_KEY_ACTION := "no_key"

var _key_label: Label
var _conflict: Label
var _key := ""
var _action_id := ""
var _settings: Dictionary = {}
var _on_done: Callable


func _init() -> void:
	title = CandyLocale.t("Shortcut")
	dialog_close_on_escape = false
	min_size = Vector2i(380, 0)

	var box := VBoxContainer.new()
	add_child(box)

	var prompt := Label.new()
	prompt.text = CandyLocale.t("Press the key, with Ctrl, Shift or Alt if you like.")
	box.add_child(prompt)

	_key_label = Label.new()
	_key_label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_key_label)

	_conflict = Label.new()
	_conflict.theme_type_variation = CandyThemeDefaults.WARNING
	_conflict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_conflict)

	var cancel := add_cancel_button(CandyLocale.t("Cancel"))
	var no_key := add_button(CandyLocale.t("No Key"), true, NO_KEY_ACTION)
	confirmed.connect(func():
		if _key != "":
			_on_done.call(_key))
	custom_action.connect(func(action: StringName):
		if action == NO_KEY_ACTION:
			hide()
			_on_done.call(""))
	#? Buttons are clicked only - keys are the shortcut.
	for button in [get_ok_button(), cancel, no_key]:
		button.focus_mode = Control.FOCUS_NONE
	window_input.connect(_on_window_input)


func open(action_label: String, current_key: String, settings: Dictionary, action_id: String,
		on_done: Callable) -> void:
	title = CandyLocale.t("Shortcut: %s") % action_label
	_action_id = action_id
	_settings = settings
	_on_done = on_done
	_show_key(current_key)
	popup_centered()


func _on_window_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	var text := CandyShortcuts.key_text(key)
	if text != "":
		_show_key(text)


func _show_key(key: String) -> void:
	_key = key
	get_ok_button().disabled = key == ""
	if key == "":
		_key_label.text = "..."
	else:
		_key_label.text = key
	var holder := ""
	if key != "":
		holder = CandyShortcuts.action_with_key(key, _settings, _action_id)
	_conflict.visible = holder != ""
	if holder != "":
		_conflict.text = CandyLocale.t("%s already has this key. OK takes it from there.") % _describe(holder)


#* Describe an action - "Copy (Navigator)":
func _describe(action_id: String) -> String:
	var action := CandyShortcuts.get_action(action_id)
	return "%s (%s)" % [str(action.get("label", action_id)), str(action.get("group", ""))]
