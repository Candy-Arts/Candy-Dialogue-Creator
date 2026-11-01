#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node

#^ Used when no panel type is given, or it no longer exists:
const DEFAULT_PANEL := "navigator"

var _entries: Dictionary = {}          #/ panel_id -> { title, source, selectable }
var _order: PackedStringArray = []


func _ready() -> void:
	register_panel("color_selector", CandyLocale.t("Color Selector"),
		func(): return CandyColorSelectorPanel.new())
	register_panel("dialogue_buttons", CandyLocale.t("Dialogue Buttons"),
		func(): return CandyDialogueButtonsPanel.new())
	register_panel("dialogue_editor", CandyLocale.t("Dialogue Editor"),
		func(): return CandyDialogueEditorPanel.new())
	register_panel("navigator", CandyLocale.t("Dialogue Navigator"),
		func(): return CandyNavigatorPanel.new())
	register_panel("inserts", CandyLocale.t("Inserts"),
		func(): return CandyInsertsPanel.new())

	#? Panels as tabs (can nest).
	register_panel("tabs", CandyLocale.t("Tabs"), func(): return CandyTabsPanel.new())

	#? System panel, not in the panel dropdown.
	register_panel("top_bar", CandyLocale.t("Top Bar"), func(): return CandyTopBarPanel.new(), false)


func register_panel(panel_id: String, title: String, source: Variant, user_selectable: bool = true) -> void:
	if not _entries.has(panel_id):
		_order.append(panel_id)
	_entries[panel_id] = {
		"title": title,
		"source": source,
		"selectable": user_selectable,
	}


func has_panel(panel_id: String) -> bool:
	return _entries.has(panel_id)


func is_selectable(panel_id: String) -> bool:
	return _entries.has(panel_id) and _entries[panel_id]["selectable"]


func get_title(panel_id: String) -> String:
	if _entries.has(panel_id):
		return _entries[panel_id]["title"]
	return panel_id


#* The panel ids an Area's dropdown offers, in registration order:
func get_selectable_ids() -> PackedStringArray:
	var result: PackedStringArray = []
	for panel_id in _order:
		if _entries[panel_id]["selectable"]:
			result.append(panel_id)
	return result


#* Make a panel (a placeholder when unknown or broken):
func instantiate(panel_id: String) -> Control:
	var node: Node = null
	if _entries.has(panel_id):
		var source = _entries[panel_id]["source"]
		if source is String:
			source = load(source)
		if source is PackedScene:
			node = source.instantiate()
		elif source is Script:
			node = source.new()
		elif source is Callable:
			node = source.call()

	if node is Control:
		return node
	if node != null:
		node.free()
	push_warning("CandyPanels: could not create panel '%s'" % panel_id)
	return CandyPlaceholderPanel.create(CandyLocale.t("Missing panel: %s") % panel_id, Color(0.35, 0.08, 0.08))