#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyCommandEditorWidget
extends CandyAreaWidget

const DEFAULT_MAP := "Commands"
const EMPTY_TEXT := "Pick a command in Type."  #/ translatable
#^ Embedded editor's height outside a Dialogue Editor, and its minimum:
const MIN_HEIGHT := 320

var _editor: CandyDialogueEditorPanel
#^ The Dialogue Editor panel this widget is in, whose height the embedded one takes:
var _outer: Control


#* Needs its map of commands:
func fits_line_type(p_config: Dictionary, line_type: String) -> bool:
	var map_id := str(p_config.get("map", DEFAULT_MAP))
	for spec in CandySchemas.field_specs(line_type):
		if spec is Dictionary and str(spec.get("id", "")) == map_id:
			return CandySchemas.is_command_map(spec)
	return false


func _on_configured() -> void:
	_editor = CandyDialogueEditorPanel.new()
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#? Fixed before entering the tree - following the selection would nest it forever.
	_editor.show_fixed([], CandyLocale.t(EMPTY_TEXT))
	var layouts := line_layouts()
	if layouts != null:
		_editor.use_layouts(layouts)

	if scrolls():
		var scroll := ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(scroll)
		#? Keeps the editor off the scrollbar, only while there is one.
		var gap := MarginContainer.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(gap)
		gap.add_child(_editor)
		var bar := scroll.get_v_scroll_bar()
		bar.visibility_changed.connect(func(): _show_gap(gap, bar.visible))
		_show_gap(gap, bar.visible)
	else:
		_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_editor)
	_fit_height()


func _show_gap(gap: MarginContainer, shown: bool) -> void:
	if shown:
		gap.theme_type_variation = CandyThemeDefaults.SCROLL_GAP
	else:
		gap.theme_type_variation = &""


func _enter_tree() -> void:
	_outer = null
	var node := get_parent()
	while node != null:
		if node is CandyDialogueEditorPanel:
			_outer = node
			break
		node = node.get_parent()
	if _outer != null:
		_outer.resized.connect(_fit_height)
	_fit_height()


func _exit_tree() -> void:
	if _outer != null and _outer.resized.is_connected(_fit_height):
		_outer.resized.disconnect(_fit_height)
	_outer = null


#* Give the embedded editor the outer Dialogue Editor's height:
func _fit_height() -> void:
	if _editor == null:
		return
	var height := float(MIN_HEIGHT)
	if _outer != null:
		height = maxf(height, _outer.size.y)
	_editor.custom_minimum_size.y = height
	if not scrolls():
		custom_minimum_size.y = height


func bind_line(line_path: Array) -> void:
	if _editor == null:
		return
	var map_id := str(config.get("map", DEFAULT_MAP))
	var commands = CandyDialogue.get_field(line_path, [map_id], {})
	var command_path: Array = []
	if commands is Dictionary:
		for key in commands:
			if str(key) != CandyDialogue.META_KEY:
				command_path = line_path + [map_id, str(key)]
				break
	_editor.show_fixed(command_path, CandyLocale.t(EMPTY_TEXT))
