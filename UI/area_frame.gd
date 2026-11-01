#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaFrame
extends Container

#^ A leaf's outline, always shown:
const LINE_WIDTH := 1.0
#^ Hovering the Area (a leaf) or its divider (a split):
const HOVER_WIDTH := 2.0
#^ Hovering its button, or its menu open:
const HIGHLIGHT_WIDTH := 3.0
const HIGHLIGHT_FILL_ALPHA := 0.12
#^ Where a dragged Area would go: its fill, border, and the label's padding:
const DROP_FILL_ALPHA := 0.3
const DROP_BORDER_WIDTH := 2.0
const DROP_LABEL_MARGIN := 6.0

var color_name: StringName = &"window"

var _content: Control
#^ Drawn over the content, so the frame takes no room:
var _overlay: Control
#^ A button shown over the content's corner while hovered, or null:
var _corner_button: CandyAreaButton = null
var _outlined := false
#^ A leaf's: hovered while the pointer is anywhere over it (see _input()):
var _tracks_hover := false
var _hovered := false
var _highlighted := false

#& Dragging (leaves with a CandyAreaDrag)
var _area: CandyAreaData = null
var _drag: CandyAreaDrag = null
#^ Over the whole Area while an Area of its layout is dragged, to catch the drop:
#? Controls inside that refuse a drop would stop it from reaching the frame.
var _catcher: Control = null
#^ The drop the pointer is over (zone -1: none), and where, to follow the keys:
var _drop_zone := -1
var _drop_mode := CandyAreaDrop.Mode.MOVE
var _drop_source: CandyAreaData = null
var _drop_point := Vector2.ZERO
var _watched_tree: SceneTree = null


#* Frame a leaf Area: outlined, highlighted while hovered:
#? button: its +. One already in the view (a header) stays there; one that isn't
#? is shown over the view's top-left corner while the Area is hovered.
#? drag: dragging the button moves the Area, and other Areas of the layout drop on it.
static func around_leaf(view: Control, button: CandyAreaButton, p_color_name: StringName,
		drag: CandyAreaDrag = null) -> CandyAreaFrame:
	var frame := CandyAreaFrame.new()
	frame.setup(view, true, p_color_name)
	frame._tracks_hover = true
	if button != null:
		button.highlight_changed.connect(func(_button_area: CandyAreaData, highlighted: bool):
			frame.set_highlighted(highlighted))
		if button.get_parent() == null:
			frame._corner_button = button
			button.visible = false
			frame._stand_out(button)
			frame.add_child(button)
		if drag != null:
			frame._enable_drag(button, drag)
	return frame


#* Frame a split Area: drawn only while its divider or button is hovered:
#? Gives the split its button, on its divider.
static func around_split(split: CandyAreaSplit, p_color_name: StringName) -> CandyAreaFrame:
	var frame := CandyAreaFrame.new()
	frame.setup(split, false, p_color_name)
	split.divider_hovered.connect(frame.set_hovered)
	var button := split.make_area_button()
	frame._stand_out(button)
	button.highlight_changed.connect(func(_button_area: CandyAreaData, highlighted: bool):
		frame.set_highlighted(highlighted))
	return frame


#* Set up the frame:
#? outlined: a thin outline even when nothing is hovered.
func setup(content: Control, outlined: bool, p_color_name: StringName) -> void:
	_content = content
	_outlined = outlined
	color_name = p_color_name
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_content)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	#Ł Hidden with its content (a filtered widget), so a split gives its space to the other side:
	visible = _content.visible
	_content.visibility_changed.connect(func(): visible = _content.visible)


#* Style a button shown over the layout, filled with the frames' color:
func _stand_out(button: CandyAreaButton) -> void:
	button.flat = false
	button.theme_type_variation = CandyThemeDefaults.area_button_type(color_name)


func set_hovered(hovered: bool) -> void:
	if hovered == _hovered:
		return
	_hovered = hovered
	_redraw()


#* Follow the pointer over a leaf's Area:
#? Not mouse_entered: Godot stops it at the first child that stops the mouse (a widget's frame).
func _input(event: InputEvent) -> void:
	if not _tracks_hover or not event is InputEventMouseMotion:
		return
	var local: InputEventMouseMotion = make_input_local(event)
	set_hovered(is_visible_in_tree() and Rect2(Vector2.ZERO, size).has_point(local.position))


func _ready() -> void:
	if _tracks_hover:
		get_window().mouse_exited.connect(set_hovered.bind(false))
	else:
		set_process_input(false)


func set_highlighted(highlighted: bool) -> void:
	_highlighted = highlighted
	_redraw()


func _redraw() -> void:
	if _overlay != null:
		_overlay.queue_redraw()
	#% Its menu keeps it shown once the mouse has gone to the menu:
	if _corner_button != null:
		_corner_button.visible = _hovered or _highlighted


func _get_minimum_size() -> Vector2:
	if _content == null:
		return Vector2.ZERO
	return _content.get_combined_minimum_size()


#* Its content's maximum size, for the split it's in (CandyAreaCap.max_of()):
func area_max_size() -> Vector2:
	return CandyAreaCap.max_of(_content)


#* Hand the room hidden Areas left to its content (CandyAreaCap.pass_growth()):
func set_area_growth(extra: Vector2, grow: Vector2i) -> void:
	CandyAreaCap.pass_growth(_content, extra, grow)


func used_height(height: float) -> float:
	return CandyAreaCap.used_height_of(_content, height)


func give_bottom(height: float, delta: float) -> void:
	CandyAreaCap.give_bottom_of(_content, height, delta)


func least_height(height: float) -> float:
	return CandyAreaCap.least_height_of(_content, height)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			if _content == null:
				return
			fit_child_in_rect(_content, Rect2(Vector2.ZERO, size))
			fit_child_in_rect(_overlay, Rect2(Vector2.ZERO, size))
			if _corner_button != null:
				fit_child_in_rect(_corner_button, Rect2(Vector2.ZERO, _corner_button.get_combined_minimum_size()))
			if _catcher != null:
				fit_child_in_rect(_catcher, Rect2(Vector2.ZERO, size))
			_redraw()
		NOTIFICATION_THEME_CHANGED:
			_redraw()
		#Ł Every control hears a drag start and end - catch drops while one of its layout's goes on:
		NOTIFICATION_DRAG_BEGIN:
			if _catcher != null and _drag.source_of(get_viewport().gui_get_drag_data()) != null:
				_catcher.visible = true
		NOTIFICATION_DRAG_END:
			if _catcher != null:
				_catcher.visible = false
				_clear_drop()


func _draw_overlay() -> void:
	var color := get_theme_color(color_name, CandyThemeDefaults.AREA_OUTLINE)
	var whole := Rect2(Vector2.ZERO, _overlay.size)
	if _highlighted:
		_overlay.draw_rect(whole, Color(color, HIGHLIGHT_FILL_ALPHA))
		_overlay.draw_rect(whole.grow(-HIGHLIGHT_WIDTH * 0.5), color, false, HIGHLIGHT_WIDTH)
	elif _hovered:
		_overlay.draw_rect(whole.grow(-HOVER_WIDTH * 0.5), color, false, HOVER_WIDTH)
	elif _outlined:
		_overlay.draw_rect(whole.grow(-LINE_WIDTH * 0.5), color, false, LINE_WIDTH)


#& Dragging

func _enable_drag(button: CandyAreaButton, drag: CandyAreaDrag) -> void:
	_area = button.area
	_drag = drag
	button.draggable = true
	button.set_drag_forwarding(_area_drag_data, Callable(), Callable())
	_catcher = Control.new()
	_catcher.visible = false
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.set_drag_forwarding(Callable(), _area_can_drop, _area_drop)
	_catcher.draw.connect(_draw_drop)
	add_child(_catcher)			#/ Last: above the content and the corner button


func _area_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = str(_drag.title_of.call(_area))
	preview.theme_type_variation = &"TooltipLabel"
	var box := PanelContainer.new()
	box.theme_type_variation = &"TooltipPanel"
	box.add_child(preview)
	set_drag_preview(box)
	return _drag.drag_data(_area)


func _area_can_drop(at_position: Vector2, data: Variant) -> bool:
	var source := _drag.source_of(data)
	if source == null:
		return false
	_drop_source = source
	_drop_point = at_position
	_update_drop()
	_watch_drop()
	return _drop_zone >= 0


func _area_drop(at_position: Vector2, data: Variant) -> void:
	var source := _drag.source_of(data)
	_drop_point = at_position
	_drop_source = source
	_update_drop()
	var zone := _drop_zone
	var mode := _drop_mode
	_clear_drop()
	if source != null and zone >= 0:
		_drag.drop.call(source, _area, zone, mode)


#* Work out the drop under the pointer, with the keys held now (zone -1 if not allowed):
func _update_drop() -> void:
	var zone := CandyAreaDrop.zone_at(_catcher.size, _drop_point)
	var mode := CandyAreaDrag.current_mode(zone)
	var allowed := bool(_drag.allows.call(_drop_source, _area, zone, mode))
	var shown_zone := -1
	if allowed:
		shown_zone = zone
	if shown_zone != _drop_zone or mode != _drop_mode:
		_drop_zone = shown_zone
		_drop_mode = mode
		_catcher.queue_redraw()


func _clear_drop() -> void:
	_drop_source = null
	if _drop_zone != -1:
		_drop_zone = -1
		_catcher.queue_redraw()
	if _watched_tree != null:
		_watched_tree.process_frame.disconnect(_follow_drop)
		_watched_tree = null


#* Follow the keys, and the pointer leaving, while it's over the Area:
#? A drag only asks again when the pointer moves.
func _watch_drop() -> void:
	if _watched_tree != null or not is_inside_tree():
		return
	_watched_tree = get_tree()
	_watched_tree.process_frame.connect(_follow_drop)


func _follow_drop() -> void:
	var inside := _catcher.get_global_rect().has_point(_catcher.get_global_mouse_position())
	if not get_viewport().gui_is_dragging() or not inside or _drop_source == null:
		_clear_drop()
		return
	_update_drop()


func _draw_drop() -> void:
	if _drop_zone < 0:
		return
	var whole := Rect2(Vector2.ZERO, _catcher.size)
	var rect := whole
	match _drop_zone:
		CandyAreaDrop.Zone.LEFT:
			rect.size.x *= 0.5
		CandyAreaDrop.Zone.RIGHT:
			rect.size.x *= 0.5
			rect.position.x += rect.size.x
		CandyAreaDrop.Zone.TOP:
			rect.size.y *= 0.5
		CandyAreaDrop.Zone.BOTTOM:
			rect.size.y *= 0.5
			rect.position.y += rect.size.y
	var color := get_theme_color(&"highlight", CandyThemeDefaults.AREA_SPLIT)
	_catcher.draw_rect(rect, Color(color, DROP_FILL_ALPHA))
	_catcher.draw_rect(rect.grow(-DROP_BORDER_WIDTH * 0.5), color, false, DROP_BORDER_WIDTH)

	#Ł What the drop does, in a tooltip-like box in the middle:
	var text := CandyAreaDrag.action_label(_drop_zone as CandyAreaDrop.Zone, _drop_mode)
	var font := get_theme_font(&"font", &"TooltipLabel")
	var font_size := get_theme_font_size(&"font_size", &"TooltipLabel")
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box_size := text_size + Vector2.ONE * DROP_LABEL_MARGIN * 2.0
	var box := Rect2(rect.get_center() - box_size * 0.5, box_size)
	_catcher.draw_style_box(get_theme_stylebox(&"panel", &"TooltipPanel"), box)
	var baseline := Vector2(box.position.x + DROP_LABEL_MARGIN,
		box.position.y + DROP_LABEL_MARGIN + font.get_ascent(font_size))
	_catcher.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		get_theme_color(&"font_color", &"TooltipLabel"))
