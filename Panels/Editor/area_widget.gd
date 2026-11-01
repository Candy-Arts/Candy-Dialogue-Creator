#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaWidget
extends Control

#^ The widget changed its settings, for the layout to store:
signal config_changed(config: Dictionary)
#^ Emitted by store_config() - stored without rebuilding the line UI:
signal config_stored(config: Dictionary)

var widget_id: String = ""
var config: Dictionary = {}
var context: Dictionary = {}


#* Whether this widget scrolls its own contents:
#? Off: it takes its full height as minimum size, and the panel scrolls.
func scrolls() -> bool:
	return bool(config.get("scroll", true))


#* Called once, when the area is built:
func configure(p_widget_id: String, p_config: Dictionary, p_context: Dictionary) -> void:
	widget_id = p_widget_id
	config = p_config
	context = p_context
	_on_configured()


#* Called when the bound line changes, and after any edit to it:
func bind_line(_line_path: Array) -> void:
	pass


#* Called on every shown widget when the line UI moves to another line:
#? Before any widget is bound; not for rebinds of the same line.
func line_changing(_line_path: Array) -> void:
	pass


#* Hide the fields filters hide, by schema path - { "Categories/Setup" = true }:
func apply_hidden_fields(_hidden_fields: Dictionary) -> void:
	pass


#* The fields a filter can hide in this widget alone, on lines of line_type (CandySchemas.field_index() entries):
#! Asked of a new widget: context holds only "line_type" and "line_layouts".
func filter_fields(_config: Dictionary, _line_type: String) -> Array:
	return []


#* What the Filters dialog lists under this widget (filter_fields() and the widget's parts):
#? A part: { "part": "category:Voice", "label", "depth" }.
func filter_outline(p_config: Dictionary, line_type: String) -> Array:
	return filter_fields(p_config, line_type)


#* Hide the parts filters hide - { "category:Voice" = true, "separator:2" = true }:
#? Called before bind_line().
func apply_hidden_parts(_hidden_parts: Dictionary) -> void:
	pass


#* The fields every widget of an area tree shows, each schema path once:
static func fields_in_tree(root: CandyAreaData, line_type: String, tree_context: Dictionary = {}) -> Array:
	var result: Array = []
	var seen := {}
	var leaves: Array[CandyAreaData] = []
	root.collect_leaves(leaves)
	for leaf in leaves:
		if not CandyWidgets.ids_of_kind("area").has(leaf.panel_id):
			continue
		var widget := CandyWidgets.instantiate_area(leaf.panel_id)
		widget.context = tree_context
		var fields: Array = widget.filter_fields(leaf.config, line_type)
		widget.free()
		for field in fields:
			if not seen.has(str(field["key"])):
				seen[str(field["key"])] = true
				result.append(field)
	return result


func _on_configured() -> void:
	pass


#* The reference linking this widget to others in the line UI:
func reference() -> String:
	var value := str(config.get("reference", CandyVariationSelection.DEFAULT_REFERENCE))
	if value.strip_edges() == "":
		return CandyVariationSelection.DEFAULT_REFERENCE
	return value.strip_edges()


#* The variation selection shared by this Editor panel's widgets, or null:
func selection() -> CandyVariationSelection:
	var value = context.get("selection")
	if value is CandyVariationSelection:
		return value
	return null


#* This Editor panel's line layouts (CandyLineLayoutSet), or null:
func line_layouts() -> CandyLineLayoutSet:
	var value = context.get("line_layouts")
	if value is CandyLineLayoutSet:
		return value
	return null


#* The Field Tree selections shared by this Editor panel's widgets, or null:
func field_selection() -> CandyFieldSelection:
	var value = context.get("field_selection")
	if value is CandyFieldSelection:
		return value
	return null


#* This Editor panel's Voice Preview / Portrait Preview link, or null:
func portrait_sync() -> CandyPortraitSync:
	var value = context.get("portrait_sync")
	if value is CandyPortraitSync:
		return value
	return null


#* Store changed settings in the layout (rebuilds the line UI):
#? Deferred: the rebuild takes this widget out of the tree, with the settings dialog or picker
#? that called this, and Godot crashes if a window leaves the tree while it's still closing.
func save_config(new_config: Dictionary) -> void:
	config = new_config
	config_changed.emit.call_deferred(new_config)


#* Store settings the widget already applied (a folded category), no rebuild:
func store_config(new_config: Dictionary) -> void:
	config = new_config
	config_stored.emit(new_config)


#* Whether this widget has settings (open_settings()):
#? False: "Options" only shows the area's minimum size.
func has_settings() -> bool:
	return false


#+ A settings dialog starts with the reference, if any, and ends with a CandyMinSizeFields.
func open_settings() -> void:
	pass


#* Whether this widget, with p_config, works on lines of line_type:
#! Asked of a new widget, never configured nor in the tree.
func fits_line_type(_config: Dictionary, _line_type: String) -> bool:
	return true


#* p_config pointed at a Variation Editor Group's variations, or null to leave it out:
#? refs: { "variation", "tts", "base", "source" }; mode: CandyVariationEditorWidget.MODE_*.
#! Asked of a new widget, like fits_line_type().
func variation_group_config(p_config: Dictionary, _refs: Dictionary, _mode: String) -> Variant:
	return p_config


#* Show sample content instead of a line (a Variation Editor Group in Edit Layout):
#! Must never write to the dialogue.
func show_placeholder() -> void:
	pass


#* Whether line_type has a top-level field field_id (for fits_line_type()):
static func has_top_field(line_type: String, field_id: String) -> bool:
	for spec in CandySchemas.field_specs(line_type):
		if spec is Dictionary and str(spec.get("id", "")) == field_id:
			return true
	return false