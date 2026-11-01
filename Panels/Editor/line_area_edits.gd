#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLineAreaEdits
extends Node
#^ Line type the widgets must fit, for saved Area layouts:
var line_type := ""

var _set_root: Callable
var _save: Callable
var _store: Callable
var _field_picker: CandyFieldPickerDialog
var _min_size_dialog: CandyMinSizeDialog


func setup(set_root: Callable, save: Callable, store: Callable) -> void:
	_set_root = set_root
	_save = save
	_store = store


#* Apply an area edit:
func apply(action: String, area: CandyAreaData, argument: Variant) -> void:
	match action:
		#? A new area beside it (the argument is [Layout, new_area_first]).
		"split", "wrap":
			var split := area.wrap_with(CandyLineLayouts.new_leaf(), argument[0], argument[1])
			if split.get_parent_area() == null:
				_set_root.call(split)
			_save.call()
		#? A new area between a split's sides.
		"insert":
			if area.is_leaf():
				return
			area.insert_between(CandyLineLayouts.new_leaf())
			_save.call()
		"close", "remove":
			_close(area)
		"swap":
			if not area.is_leaf():
				area.swap_children()
				_save.call()
		"rotate":
			if not area.is_leaf():
				area.toggle_layout()
				_save.call()
		#? Argument - the new widget id.
		"widget":
			var widget_id := str(argument)
			if area.panel_id == widget_id:
				return
			area.panel_id = widget_id
			area.config = CandyLineLayouts.default_config(widget_id)
			#? New widget - filters aimed at the old one don't follow.
			area.uid = ""
			_save.call()
		"config":
			if argument is Dictionary:
				area.config = argument
				_save.call()
		#? New settings already shown by the widget - not rebuilt.
		"store":
			if argument is Dictionary:
				area.config = argument
				_store.call()
		"scroll":
			var config := area.config.duplicate()
			config["scroll"] = bool(argument)
			area.config = config
			_save.call()
		"min_size":
			_open_min_size(area)
		#? Argument - the Fields-style widget whose fields are picked.
		"configure":
			if argument is CandyFieldsAreaWidget:
				_open_field_picker(area, argument)
		#? Argument - a saved Area layout.
		"replace":
			_replace(area, argument)
		#? An area dragged onto this one. Argument - [source area, CandyAreaDrop.Zone, CandyAreaDrop.Mode].
		"drop":
			_drop(argument[0], area, argument[1], argument[2])


#* Check whether an area can be dragged onto another of the tree:
func can_drop(source: CandyAreaData, target: CandyAreaData, zone: CandyAreaDrop.Zone,
		mode: CandyAreaDrop.Mode) -> bool:
	if not CandyAreaDrop.changes(source, target, zone, mode):
		return false
	return source.root_area() == target.root_area()


func _drop(source: CandyAreaData, target: CandyAreaData, zone: CandyAreaDrop.Zone,
		mode: CandyAreaDrop.Mode) -> void:
	if not can_drop(source, target, zone, mode):
		return
	var copy: CandyAreaData = null
	if mode == CandyAreaDrop.Mode.COPY:
		copy = CandyAreaData.from_dict(source.to_dict())
		copy.clear_uids()			#/ A new widget - the original's filters don't follow
	var old_root := target.root_area()
	var new_root := CandyAreaDrop.apply(source, target, zone, mode, copy)
	if new_root != old_root:
		_set_root.call(new_root)
	_save.call()


#* Close an area - its sibling takes the parent's place (a lone root stays):
func _close(area: CandyAreaData) -> void:
	var parent := area.get_parent_area()
	if parent == null:
		return
	parent.keep_sizes_without(area)
	var sibling := parent.sibling_of(area)
	var grandparent := parent.get_parent_area()
	if grandparent != null:
		grandparent.replace_child(parent, sibling)
	else:
		_set_root.call(sibling)
	_save.call()


func _replace(area: CandyAreaData, layout: Variant) -> void:
	if not CandyLineLayouts.area_fits(layout, line_type):
		return
	var loaded := CandyLayoutLibrary.area_from_layout(layout)
	var parent := area.get_parent_area()
	if parent == null:
		_set_root.call(loaded)
	else:
		parent.replace_child(area, loaded)
	_save.call()


#* Open the minimum size dialog (widget with no settings of its own):
func _open_min_size(area: CandyAreaData) -> void:
	if _min_size_dialog == null:
		_min_size_dialog = CandyMinSizeDialog.new()
		#? A child of this Node, which passes no theme on.
		_min_size_dialog.theme = CandyTheme.theme
		add_child(_min_size_dialog)
	_min_size_dialog.open(CandyLocale.t("%s Options") % CandyWidgets.get_title(area.panel_id),
		CandyMinSizeFields.limits_of(area.config), func(limits: Dictionary):
			var config := area.config.duplicate()
			config.merge(limits, true)
			area.config = config
			_save.call())


func _open_field_picker(area: CandyAreaData, target: CandyFieldsAreaWidget) -> void:
	if _field_picker == null:
		_field_picker = CandyFieldPickerDialog.new()
		_field_picker.theme = CandyTheme.theme
		add_child(_field_picker)
	#Ł Shared dialog - drop the previous area's connection:
	for connection in _field_picker.applied.get_connections():
		_field_picker.applied.disconnect(connection["callable"])
	_field_picker.applied.connect(func(changes: Dictionary):
		#Ł Merge, keeping settings the dialog doesn't edit (scroll):
		var config := area.config.duplicate(true)
		for key in changes:
			config[key] = changes[key]
		area.config = config
		_save.call())
	_field_picker.open(target.picker_candidates(), area.config, target.picker_options(),
		target.picker_children(), target.picker_catch_all())
