#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationEditorSettings
extends AcceptDialog

signal applied(config: Dictionary)

#^ Content column width:
#? Wrapping labels need an explicit width, or the dialog opens too tall.
const CONTENT_WIDTH := 428
const LABEL_WIDTH := 120

var _reference: LineEdit
var _translate_reference: LineEdit
var _prefix: LineEdit
var _mode: OptionButton
var _translate_scope: OptionButton
#^ One per mode with a layout, by mode id:
var _layout_pickers: Dictionary = {}
#^ The { "name", "level" } of each picker's items, in item order, by mode id:
var _layout_items: Dictionary = {}
var _min_size: CandyMinSizeFields


func _init() -> void:
	title = CandyLocale.t("Variation Editor")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(460, 0)

	var root := VBoxContainer.new()
	root.custom_minimum_size.x = CONTENT_WIDTH
	add_child(root)

	_reference = LineEdit.new()
	_add_row(root, CandyLocale.t("Main Selector"), _reference,
		CandyLocale.t("The reference of the Variation Selector whose variation the Groups are made from. In Translate mode, the language translated from."))
	_translate_reference = LineEdit.new()
	_add_row(root, CandyLocale.t("Translate To"), _translate_reference,
		CandyLocale.t("Translate mode: the reference of the Variation Selector whose language the text is translated to."))
	_prefix = LineEdit.new()
	_add_row(root, CandyLocale.t("Ref Prefix"), _prefix,
		CandyLocale.t("Starts the references of this widget's Groups: V_1, V_2... Give each Variation Editor its own, so their Groups don't mix."))

	root.add_child(HSeparator.new())

	_mode = OptionButton.new()
	for id in CandyVariationEditorWidget.MODES:
		_mode.add_item(CandyLocale.t(str(CandyVariationEditorWidget.MODE_LABELS[id])))
	CandyPopups.attach_button_popup(_mode)
	_add_row(root, CandyLocale.t("Mode"), _mode,
		CandyLocale.t("Random: a Group per random variation. TTS: the same, after the base variation, to write their TTS text. Translate: a Group per variation of both languages. Edit Layout: one Group to lay out, with placeholder text."))

	_translate_scope = OptionButton.new()
	_translate_scope.clip_text = true
	for id in CandyVariationEditorWidget.TRANSLATE_SCOPES:
		_translate_scope.add_item(CandyLocale.t(str(CandyVariationEditorWidget.TRANSLATE_SCOPE_LABELS[id])))
	CandyPopups.attach_button_popup(_translate_scope)
	_add_row(root, CandyLocale.t("Translate Groups"), _translate_scope,
		CandyLocale.t("Translate mode: which variations get a Group. The selected variation is the Main Selector's, without its random tag."))

	for id in CandyVariationEditorWidget.LAYOUT_KEYS:
		var picker := OptionButton.new()
		picker.clip_text = true
		CandyPopups.attach_button_popup(picker)
		_add_row(root, CandyLocale.t("%s layout") % CandyLocale.t(str(CandyVariationEditorWidget.MODE_LABELS[id])), picker,
			CandyLocale.t("The Group layout %s mode shows.") % CandyLocale.t(str(CandyVariationEditorWidget.MODE_LABELS[id])))
		_layout_pickers[id] = picker

	var note := Label.new()
	note.text = CandyLocale.t("Group layouts are made in Edit Layout mode, and saved with Save Area Layout... on the Group's area buttons.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = CONTENT_WIDTH
	note.theme_type_variation = CandyThemeDefaults.NOTE
	root.add_child(note)

	_min_size = CandyMinSizeFields.new()
	root.add_child(_min_size)

	confirmed.connect(_apply)
	canceled.connect(_apply)


func _add_row(root: VBoxContainer, label_text: String, field: Control, tooltip: String) -> void:
	var row := HBoxContainer.new()
	root.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	row.add_child(label)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.tooltip_text = tooltip
	row.add_child(field)


func open(config: Dictionary, line_type: String) -> void:
	_reference.text = str(config.get("reference", CandyVariationSelection.DEFAULT_REFERENCE))
	_translate_reference.text = str(config.get("translate_reference",
		CandyVariationEditorWidget.DEFAULT_TRANSLATE_REFERENCE))
	_prefix.text = str(config.get("prefix", CandyVariationEditorWidget.DEFAULT_PREFIX))
	var mode_index := CandyVariationEditorWidget.MODES.find(str(config.get("mode", CandyVariationEditorWidget.MODE_EDIT)))
	_mode.select(maxi(0, mode_index))
	var scope_index := CandyVariationEditorWidget.TRANSLATE_SCOPES.find(str(config.get("translate_scope",
		CandyVariationEditorWidget.SCOPE_WITH_RANDOMS)))
	if scope_index < 0:
		scope_index = CandyVariationEditorWidget.TRANSLATE_SCOPES.find(CandyVariationEditorWidget.SCOPE_WITH_RANDOMS)
	_translate_scope.select(scope_index)

	var saved := CandyLayoutLibrary.list(CandyLayoutLibrary.LINE_AREAS, "").filter(func(layout: Dictionary) -> bool:
		return CandyLineLayouts.area_fits(CandyLayoutLibrary.read(str(layout["path"])), line_type))
	for id in _layout_pickers:
		_fill_picker(id, saved, config.get(CandyVariationEditorWidget.LAYOUT_KEYS[id], {}))

	_min_size.load_config(config)
	#Ł The dialog is reused - drop the previous size:
	reset_size()
	popup_centered()


#* Fill a layout picker - CandyLocale.t("None"), the copy in use, then each saved layout that fits:
func _fill_picker(id: String, saved: Array, chosen: Variant) -> void:
	var picker: OptionButton = _layout_pickers[id]
	var items: Array = [{}]			#/ What the setting becomes: {} for None
	picker.clear()
	picker.add_item(CandyLocale.t("None"))
	var selected := 0
	if chosen is Dictionary and chosen.get("root") is Dictionary:
		var copy_name := str(chosen.get("name", ""))
		if copy_name == "":
			copy_name = CandyLocale.t("Unnamed")
		picker.add_item(CandyLocale.t("%s (in use)") % copy_name)
		items.append(chosen)
		selected = 1
	for layout in saved:
		picker.add_item("%s (%s)" % [layout["name"], _level_label(str(layout["level"]))])
		items.append({"name": str(layout["name"]), "level": str(layout["level"]), "path": str(layout["path"])})			#/ A file, copied on apply
	picker.select(selected)
	_layout_items[id] = items


#* What the setting becomes for an item - a file's contents with name and level, or the item:
func _copy_of(item: Dictionary) -> Dictionary:
	if not item.has("path"):
		return item.duplicate(true)
	var layout := CandyLayoutLibrary.read(str(item["path"]))
	if not layout.get("root") is Dictionary:
		return {}
	return {"name": str(item["name"]), "level": str(item["level"]), "root": layout["root"].duplicate(true)}


func _level_label(level: String) -> String:
	if level == CandyLayoutLibrary.LEVEL_USER:
		return CandyLocale.t("User")
	return CandyLocale.t("Project")


func _apply() -> void:
	var changes := {
		"reference": _reference.text.strip_edges(),
		"translate_reference": _translate_reference.text.strip_edges(),
		"prefix": _prefix.text.strip_edges(),
		"mode": CandyVariationEditorWidget.MODES[maxi(0, _mode.selected)],
		"translate_scope": CandyVariationEditorWidget.TRANSLATE_SCOPES[maxi(0, _translate_scope.selected)],
	}
	for id in _layout_pickers:
		var picker: OptionButton = _layout_pickers[id]
		var items: Array = _layout_items.get(id, [{}])
		changes[CandyVariationEditorWidget.LAYOUT_KEYS[id]] = _copy_of(items[clampi(picker.selected, 0, items.size() - 1)])
	_min_size.write_config(changes)
	applied.emit(changes)
