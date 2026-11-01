#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationGroup
extends PanelContainer

#^ The tree changed - the Variation Editor stores it and is rebuilt:
signal layout_edited(root: CandyAreaData)
#^ The tree changed, but the Group already shows it (a divider dragged):
signal layout_stored(root: CandyAreaData)
#^ The root area was saved as, or replaced by, this saved Group layout:
signal layout_named(layout_name: String, level: String)

var root: CandyAreaData
#^ Set before setup() - () -> { "name", "level" }, see layout_named:
var name_suggestion: Callable

var _line_type := ""
var _context: Dictionary = {}
var _editing := false
var _leaves: Array[CandyLineAreaLeaf] = []
var _edits: CandyLineAreaEdits
#^ Dragging areas within the Group, in Edit Layout mode:
var _drag: CandyAreaDrag


#* Build the Group:
#? context: what the widgets share (CandyLineAreaLeaf.setup()).
func setup(p_root: CandyAreaData, title: String, line_type: String, context: Dictionary, editing: bool) -> void:
	root = p_root
	_line_type = line_type
	_context = context
	_editing = editing
	theme_type_variation = CandyThemeDefaults.WIDGET_FRAME
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.theme_type_variation = CandyThemeDefaults.COMPACT_VBOX
	add_child(box)

	var label := Label.new()
	label.text = title
	label.theme_type_variation = CandyThemeDefaults.SECTION_TITLE
	label.clip_text = true
	box.add_child(label)

	if _editing:
		_edits = CandyLineAreaEdits.new()
		_edits.line_type = line_type
		add_child(_edits)
		_edits.setup(_set_root, func(): layout_edited.emit(root), func(): layout_stored.emit(root))
		_drag = CandyAreaDrag.new(
			func(area: CandyAreaData) -> String: return CandyWidgets.get_title(area.panel_id),
			_edits.can_drop,
			func(source: CandyAreaData, target: CandyAreaData, zone: CandyAreaDrop.Zone, mode: CandyAreaDrop.Mode) -> void:
				_edits.apply("drop", target, [source, zone, mode]))

	var view := _build(root)
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(view)


func _set_root(new_root: CandyAreaData) -> void:
	new_root.set_parent_area(null)
	root = new_root


func bind_line(line_path: Array) -> void:
	for leaf in _leaves:
		leaf.bind_line(line_path)


func apply_hidden_fields(hidden_fields: Dictionary) -> void:
	for leaf in _leaves:
		leaf.apply_hidden_fields(hidden_fields)


func show_placeholder() -> void:
	for leaf in _leaves:
		leaf.widget.show_placeholder()


func _build(area: CandyAreaData) -> Control:
	if area.is_leaf():
		var leaf := CandyLineAreaLeaf.new()
		leaf.setup(area, _line_type, _editing, _context)
		_leaves.append(leaf)
		if not _editing:
			return CandyAreaCap.around(leaf, area.config)
		leaf.edit_requested.connect(_edits.apply)
		if area == root:
			_hook_root_menu(leaf.area_layout_menu())
		return CandyAreaCap.around(CandyAreaFrame.around_leaf(leaf, leaf.area_button, &"editor", _drag), area.config)

	var split := CandyAreaSplit.new()
	split.setup(area, _build(area.first), _build(area.second))
	if not _editing:
		return split
	split.ratio_changed.connect(func(): layout_stored.emit(root))
	split.enable_menu(CandyWidgets.get_title, Callable())
	split.enable_layouts(CandyLayoutLibrary.LINE_AREAS,
		func(split_area: CandyAreaData) -> Dictionary: return CandyLayoutLibrary.area_layout(split_area),
		func(layout: Dictionary) -> bool: return CandyLineLayouts.area_fits(layout, _line_type))
	split.edit_requested.connect(_edits.apply)
	if area == root:
		_hook_root_menu(split.area_layout_menu())
	return CandyAreaFrame.around_split(split, &"editor")


func _hook_root_menu(menu: CandyLayoutMenu) -> void:
	if menu == null:
		return
	menu.suggest = name_suggestion
	menu.saved.connect(func(layout_name: String, level: String): layout_named.emit(layout_name, level))
	menu.loaded.connect(func(layout_name: String, level: String): layout_named.emit(layout_name, level))


#* A Group layout's tree with every widget pointed at one Group's variations:
static func for_variation(layout_root: CandyAreaData, refs: Dictionary, mode: String) -> CandyAreaData:
	var result := layout_root
	var leaves: Array[CandyAreaData] = []
	layout_root.collect_leaves(leaves)
	for leaf in leaves:
		#? A new widget, never configured nor added to the tree - only asked.
		var widget := CandyWidgets.instantiate_area(leaf.panel_id)
		var config = widget.variation_group_config(leaf.config, refs, mode)
		widget.free()
		if config is Dictionary:
			leaf.config = config
			continue
		#% Opted out - its sibling takes its place:
		var parent := leaf.get_parent_area()
		if parent == null:
			return null		#/ None left
		var sibling := parent.sibling_of(leaf)
		var grandparent := parent.get_parent_area()
		if grandparent != null:
			grandparent.replace_child(parent, sibling)
		else:
			sibling.set_parent_area(null)
			result = sibling
	return result
