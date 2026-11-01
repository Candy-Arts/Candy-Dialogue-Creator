#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPlaceholderPanel
extends CandyPanel

var title: String = "Panel"
var tint: Color = Color(0.15, 0.15, 0.15)

var _notes: TextEdit
var _pending_text: String = ""


static func create(p_title: String, p_tint: Color) -> CandyPlaceholderPanel:
	var panel := CandyPlaceholderPanel.new()
	panel.title = p_title
	panel.tint = p_tint
	return panel


func _ready() -> void:
	var background := ColorRect.new()
	background.color = tint
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.theme_type_variation = CandyThemeDefaults.PANEL_MARGIN
	add_child(margin)

	_notes = TextEdit.new()
	_notes.placeholder_text = CandyLocale.t("%s — type here. This text survives layout changes and is saved on quit.") % title
	_notes.text = _pending_text
	margin.add_child(_notes)


func get_state() -> Dictionary:
	if _notes != null:
		return {"notes": _notes.text}
	return {"notes": _pending_text}


func set_state(state: Dictionary) -> void:
	_pending_text = str(state.get("notes", ""))
	if _notes != null:
		_notes.text = _pending_text