#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySpeechInsertMenus
extends RefCounted

#^ A drop-down's id among an Inserts panel's inserts - PREFIX + its menu:
const PREFIX := "speech_menu:"
#^ Every drop-down, in the default order:
const MENUS: Array = ["text_events", "lexicon", "all"]
#^ The ones a new Inserts panel shows, in their own category:
const DEFAULT_MENUS: Array = ["text_events", "lexicon"]
const CATEGORY := "Speech"	#/ translatable
const MENU_LABELS := {
	"text_events": "Text Events",	#/ translatable
	"lexicon": "Lexicon",	#/ translatable
	"all": "Speech Inserts",	#/ translatable
}
const MENU_TOOLTIPS := {
	"text_events": "Types a text event's marker into the text: the line's own events and the project's, for the variation of the Speech Editor being typed in.",	#/ translatable
	"lexicon": "Types a Lexicon keyword into the text, for the variation of the Speech Editor being typed in.",	#/ translatable
	"all": "Text events and Lexicon keywords, in one drop-down.",	#/ translatable
}
#^ Names in the Buttons settings, where the label alone wouldn't say what it holds:
const MENU_TITLES := {
	"text_events": "Text Events (drop-down)",	#/ translatable
	"lexicon": "Lexicon (drop-down)",	#/ translatable
	"all": "All: Text Events and Lexicon (drop-down)",	#/ translatable
}

const SECTION_TEXT_EVENTS := "Text Events"	#/ translatable
const SECTION_LEXICON := "Lexicon"	#/ translatable

#^ The text field the open drop-down types into - the one focused when it opened:
var _target: Control = null
#^ What each item of the open drop-down types, by its id:
var _item_texts: Dictionary = {}


#& Ids

static func is_menu(id: Variant) -> bool:
	return str(id).begins_with(PREFIX) and MENUS.has(menu_of(id))


static func id_of(menu: String) -> String:
	return PREFIX + menu


static func menu_of(id: Variant) -> String:
	return str(id).trim_prefix(PREFIX)


static func title_of(id: Variant) -> String:
	return str(MENU_TITLES.get(menu_of(id), id))


static func tooltip_of(id: Variant) -> String:
	return str(MENU_TOOLTIPS.get(menu_of(id), ""))


#* Every drop-down's id, in the default order:
static func all_ids() -> Array:
	var result: Array = []
	for menu in MENUS:
		result.append(id_of(str(menu)))
	return result


#& Building

#* A drop-down button for a drop-down's id:
func make_button(id: String) -> MenuButton:
	var menu := menu_of(id)
	var button := MenuButton.new()
	button.text = CandyLocale.t(str(MENU_LABELS[menu]))
	button.tooltip_text = CandyLocale.t(str(MENU_TOOLTIPS[menu]))
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE  #/ Keeps the focus on the text field
	var popup := button.get_popup()
	#? Items are made as it opens, for the text field and variation of that moment.
	button.about_to_popup.connect(_fill.bind(popup, menu))
	popup.id_pressed.connect(_on_item_pressed)
	return button


#* Fill a drop-down with what it lists now:
func _fill(popup: PopupMenu, menu: String) -> void:
	popup.clear()
	_item_texts.clear()
	_target = CandyInserts.text_target()

	#Ł The line and variation of the Speech Editor typed in; the active line's Default otherwise:
	var editor := speech_editor_of(_target)
	var variation := CandyVariationSelection.DEFAULT_VARIATION
	var line_path: Array = CandyDialogue.active_path
	if editor != null:
		line_path = editor.edited_line_path()
		if editor.edited_variation() != "":
			variation = editor.edited_variation()

	if _target == null:
		_add_note(popup, CandyLocale.t("Click in the text first: inserts are typed where its caret is."))
	elif editor == null:
		_add_note(popup, CandyLocale.t("Not in a Speech Editor: listed for the %s variation.") % variation)

	match menu:
		"text_events":
			_add_text_events(popup, line_path, variation, false)
		"lexicon":
			_add_lexicon(popup, variation, false)
		"all":
			_add_text_events(popup, line_path, variation, true)
			_add_lexicon(popup, variation, true)
	popup.reset_size()


#* The Speech Editor a text field belongs to, or null:
static func speech_editor_of(target: Control) -> CandySpeechEditorWidget:
	var node: Node = target
	while node != null:
		if node is CandySpeechEditorWidget:
			return node
		node = node.get_parent()			#/ Through windows too: a tag popup belongs to its editor
	return null


func _add_text_events(popup: PopupMenu, line_path: Array, variation: String, titled: bool) -> void:
	if titled:
		popup.add_separator(CandyLocale.t(SECTION_TEXT_EVENTS))
	if CandyTextEventMarkers.marker("x") == "":
		_add_note(popup, CandyLocale.t("No text event symbols: set them in Settings > Project > Symbols."))
		return

	var line_events = null
	if CandyDialogue.is_line_path(line_path):
		line_events = CandyDialogue.get_field(line_path, [CandyTextEventMarkers.EVENTS_FIELD], null)
	var own: Array = CandyResources.names_matching(CandyTextEventMarkers.line_events(line_events), variation)
	var shared: Array = CandyResources.speech_insert_names(CandyResources.TEXT_EVENTS, variation)
	var names: Array = own.duplicate()
	for event_name in shared:
		if not names.has(event_name):
			names.append(event_name)
	names.sort_custom(func(a, b): return str(a).naturalnocasecmp_to(str(b)) < 0)
	if names.is_empty():
		_add_note(popup, CandyLocale.t("No text events for %s.") % variation)
		return

	for event_name in names:
		var tooltip := CandyLocale.t("From the project's text events table.")
		if own.has(event_name):
			tooltip = CandyLocale.t("This line's own text event.")
		_add_item(popup, str(event_name), CandyTextEventMarkers.marker(str(event_name)), tooltip)


func _add_lexicon(popup: PopupMenu, variation: String, titled: bool) -> void:
	if titled:
		popup.add_separator(CandyLocale.t(SECTION_LEXICON))
	var keywords: Array = CandyResources.speech_insert_names(CandyResources.LEXICON, variation)
	if keywords.is_empty():
		_add_note(popup, CandyLocale.t("No Lexicon keywords for %s.") % variation)
		return
	for keyword in keywords:
		_add_item(popup, str(keyword), str(keyword), CandyLocale.t("A Lexicon keyword."))


func _add_item(popup: PopupMenu, label: String, text: String, tooltip: String) -> void:
	var id := _item_texts.size()
	popup.add_item(label, id)
	var index := popup.get_item_index(id)
	popup.set_item_tooltip(index, tooltip + "\n" + CandyLocale.t("Types: %s") % text)
	_item_texts[id] = text


#* A disabled line of the drop-down - why it lists nothing, or what to do:
func _add_note(popup: PopupMenu, text: String) -> void:
	popup.add_item(text)
	popup.set_item_disabled(popup.item_count - 1, true)


func _on_item_pressed(id: int) -> void:
	if not _item_texts.has(id):
		return
	if CandyInserts.apply_text_to(_target, str(_item_texts[id]), "", ""):
		_target.grab_focus()
