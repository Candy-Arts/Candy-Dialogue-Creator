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

const DEFAULT_FIELD_WIDGET := "line_edit"

var _entries: Dictionary = {}    #/ id -> { title, source, kind }
var _order: PackedStringArray = []


func _ready() -> void:
	register_widget("advanced_speech_editor", CandyLocale.t("Advanced Speech Editor"),
		func(): return CandyAdvancedSpeechEditorWidget.new(), "area")
	register_widget("color", CandyLocale.t("Color"), func(): return CandyColorFieldWidget.new())
	register_widget("command_editor", CandyLocale.t("Command Editor"),
		func(): return CandyCommandEditorWidget.new(), "area")
	register_widget("counters", CandyLocale.t("Counters"),
		func(): return CandyCountersWidget.new(), "area")
	register_widget("fields", CandyLocale.t("Fields"), func(): return CandyFieldsAreaWidget.new(), "area")
	register_widget("field_tree", CandyLocale.t("Field Tree"),
		func(): return CandyFieldTreeWidget.new(), "area")
	register_widget("line_edit", CandyLocale.t("Text Field"), func(): return CandyLineEditWidget.new())
	register_widget("portrait_preview", CandyLocale.t("Portrait Preview"),
		func(): return CandyPortraitPreviewWidget.new(), "area")
	register_widget("speech_editor", CandyLocale.t("Speech Editor"),
		func(): return CandySpeechEditorWidget.new(), "area")
	register_widget("speech_viewer", CandyLocale.t("Speech Viewer"),
		func(): return CandySpeechViewerWidget.new(), "area")
	register_widget("text_edit", CandyLocale.t("Multi-line Text"), func(): return CandyTextEditWidget.new())
	register_widget("text_event_editor", CandyLocale.t("Text Event Editor"),
		func(): return CandyTextEventEditorWidget.new(), "area")
	register_widget("variation_properties", CandyLocale.t("Variation Properties"),
		func(): return CandyVariationPropertiesWidget.new(), "area")
	register_widget("variation_editor", CandyLocale.t("Variation Editor"),
		func(): return CandyVariationEditorWidget.new(), "area")
	register_widget("variation_selector", CandyLocale.t("Variation Selector"),
		func(): return CandyVariationSelectorWidget.new(), "area")
	register_widget("voice_preview", CandyLocale.t("Voice Preview"),
		func(): return CandyVoicePreviewWidget.new(), "area")


func register_widget(id: String, title: String, source: Variant, kind: String = "field") -> void:
	if not _entries.has(id):
		_order.append(id)
	_entries[id] = {"title": title, "source": source, "kind": kind}


func has_widget(id: String) -> bool:
	return _entries.has(id)


func get_title(id: String) -> String:
	if _entries.has(id):
		return str(_entries[id]["title"])
	return id


func ids_of_kind(kind: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for id in _order:
		if _entries[id]["kind"] == kind:
			result.append(id)
	return result


#* Make a field widget:
func instantiate_field(id: String) -> CandyFieldWidget:
	var node := _instantiate(id)
	if node is CandyFieldWidget:
		return node
	if node != null:
		node.free()
	#% Unknown id - fall back to a text field, so the data stays editable:
	if id != DEFAULT_FIELD_WIDGET:
		push_warning("CandyWidgets: unknown field widget '%s', using %s" % [id, DEFAULT_FIELD_WIDGET])
		return instantiate_field(DEFAULT_FIELD_WIDGET)
	return CandyLineEditWidget.new()


#* Make an area widget:
func instantiate_area(id: String) -> CandyAreaWidget:
	var node := _instantiate(id)
	if node is CandyAreaWidget:
		return node
	if node != null:
		node.free()
	#% Unknown id - fall back to a Fields widget, so a layout using a missing mod widget still opens:
	if id != "fields":
		push_warning("CandyWidgets: unknown area widget '%s', using fields" % id)
		return instantiate_area("fields")
	return CandyFieldsAreaWidget.new()


func _instantiate(id: String) -> Node:
	if not _entries.has(id):
		return null
	var source = _entries[id]["source"]
	if source is String:
		source = load(source)
	if source is PackedScene:
		return source.instantiate()
	if source is Script:
		return source.new()
	if source is Callable:
		return source.call()
	return null