#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLayoutsSettingsPage
extends CandySettingsPage

var _list: VBoxContainer
var _checks: Array = []    #/ { "check": CheckBox, "layout": { "name", "level", "path" } }


func build() -> void:
	add_heading(CandyLocale.t("Quick layouts"))
	add_note(CandyLocale.t("The window layouts listed in the top bar's Window menu. Save a layout with Window > Save Layout... to add it here."))
	_list = VBoxContainer.new()
	add_custom(_list)


func refresh() -> void:
	super.refresh()
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_checks.clear()

	var layouts := CandyLayoutLibrary.list(CandyLayoutLibrary.WINDOWS, "")
	if layouts.is_empty():
		var empty := Label.new()
		empty.text = CandyLocale.t("No saved window layouts yet.")
		empty.theme_type_variation = CandyThemeDefaults.NOTE
		_list.add_child(empty)
		return

	var chosen = draft.get_value(CandyLayoutLibrary.QUICK_SETTING, [])
	var current_level := ""
	for layout in layouts:
		if layout["level"] != current_level:
			current_level = layout["level"]
			var heading := Label.new()
			if current_level == CandyLayoutLibrary.LEVEL_USER:
				heading.text = CandyLocale.t("User")
			else:
				heading.text = CandyLocale.t("Project")
			_list.add_child(heading)
		var check := CheckBox.new()
		check.text = str(layout["name"])
		check.set_pressed_no_signal(CandyLayoutLibrary.is_quick(chosen, layout))
		check.toggled.connect(func(_pressed: bool): _write_chosen())
		_list.add_child(check)
		_checks.append({"check": check, "layout": layout})


#* Store the checked layouts, in list order:
func _write_chosen() -> void:
	var chosen: Array = []
	for entry in _checks:
		if (entry["check"] as CheckBox).button_pressed:
			chosen.append({"name": str(entry["layout"]["name"]), "level": str(entry["layout"]["level"])})
	draft.set_value(CandyLayoutLibrary.QUICK_SETTING, chosen)
