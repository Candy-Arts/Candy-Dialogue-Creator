#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationEditorWidget
extends CandyAreaWidget

const VARIATIONS_FIELD := "Variations"
const MODE_RANDOM := "random"
const MODE_TTS := "tts"
const MODE_TRANSLATE := "translate"
const MODE_EDIT := "edit_layout"
const MODES := [MODE_RANDOM, MODE_TTS, MODE_TRANSLATE, MODE_EDIT]
const MODE_LABELS := {MODE_RANDOM: "Random", MODE_TTS: "TTS", MODE_TRANSLATE: "Translate",  #/ translatable
	MODE_EDIT: "Edit Layout"}  #/ translatable
const LAYOUT_KEYS := {MODE_RANDOM: "random_layout", MODE_TTS: "tts_layout",
	MODE_TRANSLATE: "translate_layout"}
const DEFAULT_PREFIX := "V"
const DEFAULT_TRANSLATE_REFERENCE := "2"
const SCOPE_ALL := "all"
const SCOPE_WITH_RANDOMS := "with_randoms"
const SCOPE_VARIATION := "variation"
const TRANSLATE_SCOPES := [SCOPE_ALL, SCOPE_WITH_RANDOMS, SCOPE_VARIATION]
const TRANSLATE_SCOPE_LABELS := {
	SCOPE_ALL: "All variations of both languages",  #/ translatable
	SCOPE_WITH_RANDOMS: "The selected variation and its randoms",  #/ translatable
	SCOPE_VARIATION: "The selected variation only",  #/ translatable
}
#^ Between the two variations in a Translate mode Group's title:
const TRANSLATE_ARROW := "  →  "
#^ Ends the reference of a Translate mode Group's source variation:
const SOURCE_SUFFIX := "_From"
#^ What the widgets show in Edit Layout mode (CandyAreaWidget.show_placeholder()):
const PLACEHOLDER_TEXT := "Placeholder text. In the other modes, each Group shows its own variation here."  #/ translatable
const PLACEHOLDER_VARIATION := "Variation"  #/ translatable
const EDIT_TITLE := "Group layout (placeholder text)"  #/ translatable
const DEFAULT_GROUP_WIDGET := "speech_editor"

var _message: Label
var _groups_box: VBoxContainer
var _groups: Array[CandyVariationGroup] = []
var _settings: CandyVariationEditorSettings
var _line_path: Array = []
#^ What the Groups were made from (see _source_key()), "" before:
var _source := ""
var _built := false
var _hidden_fields: Dictionary = {}


#* Needs the line's Variations:
func fits_line_type(_config: Dictionary, line_type: String) -> bool:
	return has_top_field(line_type, VARIATIONS_FIELD)


func _on_configured() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme_type_variation = CandyThemeDefaults.COMPACT_VBOX
	add_child(root)

	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.visible = false
	root.add_child(_message)

	_groups_box = VBoxContainer.new()
	_groups_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if scrolls():
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		root.add_child(scroll)
		#? Keeps the Groups off the scrollbar, only while there is one.
		var gap := MarginContainer.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(gap)
		gap.add_child(_groups_box)
		var bar := scroll.get_v_scroll_bar()
		bar.visibility_changed.connect(func(): _show_gap(gap, bar.visible))
		_show_gap(gap, bar.visible)
	else:
		#? The stack's height is the widget's minimum, so the panel scrolls instead.
		root.add_child(_groups_box)
		root.minimum_size_changed.connect(update_minimum_size)

	var shared := selection()
	if shared != null:
		shared.changed.connect(_on_selection_changed)
	#? Variations switched on or off in Settings > Variations.
	CandyProfiles.settings_changed.connect(_on_setting_changed)


func _show_gap(gap: MarginContainer, shown: bool) -> void:
	if shown:
		gap.theme_type_variation = CandyThemeDefaults.SCROLL_GAP
	else:
		gap.theme_type_variation = &""


func _get_minimum_size() -> Vector2:
	if scrolls() or get_child_count() == 0:
		return Vector2.ZERO
	return get_child(0).get_combined_minimum_size()


func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	#? Groups stay while the source is the same, so nothing being typed is rebuilt away.
	if not _built or (mode() != MODE_EDIT and _source_key() != _source):
		_rebuild()
		return
	if mode() != MODE_EDIT:
		for group in _groups:
			group.bind_line(_line_path)


func apply_hidden_fields(hidden_fields: Dictionary) -> void:
	_hidden_fields = hidden_fields
	for group in _groups:
		group.apply_hidden_fields(hidden_fields)


#* The fields of the current mode's Group layout (a filter hides one in every Group):
func filter_fields(p_config: Dictionary, line_type: String) -> Array:
	var root: CandyAreaData = null
	var mode_now := str(p_config.get("mode", MODE_EDIT))
	if LAYOUT_KEYS.has(mode_now):
		root = CandyLayoutLibrary.area_from_layout(p_config.get(LAYOUT_KEYS[mode_now], {}))
	else:
		var stored = p_config.get("group_layout", {})
		if stored is Dictionary and not stored.is_empty():
			root = CandyAreaData.from_dict(stored.duplicate(true))
	if root == null:
		return []
	return fields_in_tree(root, line_type, context)


func mode() -> String:
	var value := str(config.get("mode", MODE_EDIT))
	if MODES.has(value):
		return value
	return MODE_EDIT


func prefix() -> String:
	var value := str(config.get("prefix", DEFAULT_PREFIX)).strip_edges()
	if value == "":
		return DEFAULT_PREFIX
	return value


func translate_reference() -> String:
	var value := str(config.get("translate_reference", DEFAULT_TRANSLATE_REFERENCE)).strip_edges()
	if value == "":
		return DEFAULT_TRANSLATE_REFERENCE
	return value


func translate_scope() -> String:
	var value := str(config.get("translate_scope", SCOPE_WITH_RANDOMS))
	if TRANSLATE_SCOPES.has(value):
		return value
	return SCOPE_WITH_RANDOMS


#* What the Groups are made from; they're rebuilt when it changes:
func _source_key() -> String:
	if mode() != MODE_TRANSLATE:
		return _base_variation()
	var key := "%s>%s" % [_language_of(reference()), _language_of(translate_reference())]
	if translate_scope() != SCOPE_ALL:
		key += "|" + _base_variation()
	return key


func _selected(selector_reference: String) -> String:
	var shared := selection()
	if shared == null:
		return CandyVariationSelection.DEFAULT_VARIATION
	return shared.get_selected(selector_reference)


#* The Main Selector's variation, without its random and TTS tags:
func _base_variation() -> String:
	return str(CandyVariations.split_variation(_selected(reference()))["base"])


func _language_of(selector_reference: String) -> String:
	return _selected(selector_reference).split(CandyVariations.SEPARATOR)[0]


#& Groups

func _rebuild() -> void:
	if _groups_box == null:
		return
	_release_focus_inside()
	for group in _groups:
		_groups_box.remove_child(group)
		group.queue_free()
	_groups.clear()
	_show_message("", false)
	_built = true
	_source = _source_key()

	if mode() == MODE_EDIT:
		_build_edit_group()
		return

	var layout_root := _mode_layout()
	if layout_root == null:
		return
	var variations: Array = []
	if mode() == MODE_TRANSLATE:
		var language := _language_of(reference())
		if language == _language_of(translate_reference()):
			_show_message(CandyLocale.t("Both selectors are on %s. Pick another language to translate to.") % language, false)
			return
		variations = _translate_variations()
	else:
		variations = _group_variations()
	if variations.is_empty():
		if mode() == MODE_TRANSLATE:
			_show_message(CandyLocale.t("Neither language has enabled variations."), false)
		else:
			_show_message(CandyLocale.t("%s has no random variations. Add random tags in Settings > Languages & Tags.") % _source, false)
		return

	#Ł Published first - the widgets read their variation when bound:
	var shared := selection()
	if shared != null:
		for entry in variations:
			var refs: Dictionary = entry["refs"]
			shared.select(refs["variation"], entry["variation"])
			shared.select(refs["tts"], CandyVariations.tts_of(entry["variation"]))
			if entry.has("source"):
				shared.select(refs["source"], entry["source"])

	for entry in variations:
		var copy := CandyLayoutLibrary.area_from_layout(CandyLayoutLibrary.area_layout(layout_root))
		var group_root := CandyVariationGroup.for_variation(copy, entry["refs"], mode())
		if group_root == null:
			continue
		_add_group(group_root, str(entry["title"]), context, false)

	for group in _groups:
		group.apply_hidden_fields(_hidden_fields)
		group.bind_line(_line_path)


#* Random and TTS mode's Groups, in order, with their references:
func _group_variations() -> Array:
	var data := CandyVariationData.new(CandySettingsDraft.new())
	var result: Array = []
	var base := _base_variation()
	var base_ref := _ref(0)
	var names: Array = []
	if mode() == MODE_TTS:
		names.append(base)
	names.append_array(CandyVariations.random_variations(base, data.random_tags(), data.disabled()))
	for variation_name in names:
		var number := CandyVariations.random_number(str(CandyVariations.split_variation(variation_name)["random"]))
		var title := str(variation_name)
		if mode() == MODE_TTS:
			title = CandyVariations.tts_of(title)
		result.append({"variation": variation_name, "title": title, "refs": _refs(number, base_ref)})
	#Ł The base is published even without a Group - Random mode's Counters compare with it:
	var shared := selection()
	if shared != null:
		shared.select(base_ref, base)
	return result		#/ refs: { "variation", "tts", "base", "source" }


#* Translate mode's Groups: one per variation enabled in either language, in list order:
func _translate_variations() -> Array:
	var data := CandyVariationData.new(CandySettingsDraft.new())
	var disabled := data.disabled()
	var custom := data.custom_tags()
	var randoms := data.random_tags()
	var from_language := _language_of(reference())
	var to_language := _language_of(translate_reference())
	var from_enabled := _enabled_variations(from_language, custom, randoms, disabled)
	var to_enabled := _enabled_variations(to_language, custom, randoms, disabled)

	var result: Array = []
	for tags in _translate_tag_parts(custom, randoms):
		var from_name := _with_tags(from_language, str(tags))
		var to_name := _with_tags(to_language, str(tags))
		if not from_enabled.has(from_name) and not to_enabled.has(to_name):
			continue
		var refs := _refs(result.size() + 1, _ref(0))
		result.append({"variation": to_name, "source": from_name,	#/ Translated to, from
			"title": from_name + TRANSLATE_ARROW + to_name, "refs": refs})
	return result


#* The tag part of each Translate Group ("" for the bare language), by translate_scope():
func _translate_tag_parts(custom: Array, randoms: Array) -> Array:
	if translate_scope() == SCOPE_ALL:
		var all_parts: Array = [""]
		all_parts.append_array(CandyVariations.ordered_tag_variations(custom, randoms, []))
		return all_parts
	var base_parts := _base_variation().split(CandyVariations.SEPARATOR)
	base_parts.remove_at(0)
	var tags := CandyVariations.SEPARATOR.join(base_parts)
	var result: Array = [tags]
	if translate_scope() == SCOPE_WITH_RANDOMS:
		for random in randoms:
			var tag := str(random).strip_edges()
			if tag == "":
				continue
			if tags == "":
				result.append(tag)
			else:
				result.append(tags + CandyVariations.SEPARATOR + tag)
	return result


#* A language's enabled variations, as a set (none if the language is disabled):
func _enabled_variations(language: String, custom: Array, randoms: Array, disabled: Array) -> Dictionary:
	var result := {}
	if disabled.has(language):
		return result
	var tag_variations := CandyVariations.ordered_tag_variations(custom, randoms, disabled)
	for variation_name in CandyVariations.language_variations(language, tag_variations, disabled):
		result[variation_name] = true
	return result


func _with_tags(language: String, tags: String) -> String:
	if tags == "":
		return language
	return language + CandyVariations.SEPARATOR + tags


#* "V_2" - the reference of random variation #2's Group; 0 for the base one:
func _ref(number: int) -> String:
	return "%s_%d" % [prefix(), number]


func _refs(number: int, base_ref: String) -> Dictionary:
	var variation_ref := _ref(number)
	return {"variation": variation_ref, "tts": variation_ref + "_" + CandyVariations.TTS_TAG, "base": base_ref,
		"source": variation_ref + SOURCE_SUFFIX}


#* The current mode's Group layout (the settings' copy), or null with the reason shown:
func _mode_layout() -> CandyAreaData:
	var chosen = config.get(LAYOUT_KEYS[mode()], {})
	var mode_label := CandyLocale.t(str(MODE_LABELS[mode()]))
	if not chosen is Dictionary or not chosen.get("root") is Dictionary:
		_show_message(CandyLocale.t("No Group layout chosen for %s mode. Choose one in Options.") % mode_label, true)
		return null
	var layout_name := str(chosen.get("name", ""))
	var line_type := str(context.get("line_type", ""))
	var layout_root := CandyLayoutLibrary.area_from_layout(chosen)
	if layout_root == null or not CandyLineLayouts.area_fits(chosen, line_type):
		_show_message(CandyLocale.t("The Group layout \"%s\" doesn't fit this line type. Choose another one in Options.") % layout_name, true)
		return null
	return layout_root


#* Edit Layout mode's single Group, on sample content:
func _build_edit_group() -> void:
	var group_root: CandyAreaData = null
	var stored = config.get("group_layout", {})
	if stored is Dictionary and not stored.is_empty():
		group_root = CandyAreaData.from_dict(stored.duplicate(true))
	if group_root == null:
		group_root = CandyAreaData.make_leaf(DEFAULT_GROUP_WIDGET)

	#? Selections of its own, so no real variation reaches its widgets.
	var edit_context := context.duplicate()
	edit_context["selection"] = CandyVariationSelection.new()
	edit_context["field_selection"] = CandyFieldSelection.new()
	edit_context["portrait_sync"] = CandyPortraitSync.new()
	var group := CandyVariationGroup.new()
	group.name_suggestion = func() -> Variant: return config.get("group_layout_name", {})
	group.layout_named.connect(_store_group_layout_name)
	group = _add_group(group_root, CandyLocale.t(EDIT_TITLE), edit_context, true, group)
	group.layout_edited.connect(func(edited: CandyAreaData): _store_group_layout(edited, true))
	group.layout_stored.connect(func(edited: CandyAreaData): _store_group_layout(edited, false))
	group.show_placeholder()


#* Add a Group (group = one made beforehand, to set up before its areas are built):
func _add_group(group_root: CandyAreaData, title: String, group_context: Dictionary, editing: bool,
		group: CandyVariationGroup = null) -> CandyVariationGroup:
	if group == null:
		group = CandyVariationGroup.new()
	group.setup(group_root, title, str(context.get("line_type", "")), group_context, editing)
	_groups_box.add_child(group)
	_groups.append(group)
	return group


#* Store the Group layout:
func _store_group_layout(edited: CandyAreaData, rebuild: bool) -> void:
	var merged := config.duplicate(true)
	merged["group_layout"] = edited.to_dict().duplicate(true)
	if rebuild:
		save_config(merged)		#/ Saved: rebuilds the line UI
	else:
		store_config(merged)	#/ Only kept: already shown (e.g. a divider drag)


#* Store the layout's name, without a rebuild (a load that follows rebuilds):
func _store_group_layout_name(layout_name: String, level: String) -> void:
	var merged := config.duplicate(true)
	merged["group_layout_name"] = {"name": layout_name, "level": level}
	store_config(merged)


func _show_message(text: String, is_error: bool) -> void:
	_message.text = text
	_message.visible = text != ""
	if is_error:
		_message.theme_type_variation = CandyThemeDefaults.ERROR
	else:
		_message.theme_type_variation = CandyThemeDefaults.NOTE


func _release_focus_inside() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var focused := viewport.gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		focused.release_focus()


#& Input

func _on_selection_changed(changed_reference: String, _variation_name: String) -> void:
	if mode() == MODE_EDIT or not _built:
		return
	if changed_reference != reference() and changed_reference != translate_reference():
		return
	if _source_key() != _source:
		_rebuild()


func _on_setting_changed(key: String) -> void:
	if key == CandyVariationData.DATA_KEY and _built:
		_rebuild()


#& Settings

func has_settings() -> bool:
	return true


func open_settings() -> void:
	if _settings == null:
		_settings = CandyVariationEditorSettings.new()
		_settings.applied.connect(_on_settings_applied)
		add_child(_settings)
	_settings.open(config, str(context.get("line_type", "")))


#* Save the settings (rebuilds the line UI):
func _on_settings_applied(changes: Dictionary) -> void:
	var merged := config.duplicate(true)
	for key in changes:
		merged[key] = changes[key]
	save_config(merged)
