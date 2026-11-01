#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPopups

#^ Meta (true) on a control opening its own menu on right-click:
const OWN_CONTEXT_MENU := &"candy_own_context_menu"


#* Whether an event is a right-click for an Area's menu:
#! Areas check in _input(), before controls: a non-text control handling
#! right-clicks itself must set OWN_CONTEXT_MENU.
static func is_context_click(event: InputEvent, area: Control) -> bool:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_RIGHT:
		return false
	if not area.is_visible_in_tree():
		return false
	#% The hovered control is area or inside it, with no own menu up to area:
	var hovered := area.get_viewport().gui_get_hovered_control()
	if hovered == null or not (hovered == area or area.is_ancestor_of(hovered)):
		return false
	var node: Node = hovered
	while node != null:
		if node is Control and _has_own_menu(node):
			return false
		if node == area:
			break
		node = node.get_parent()
	return true


static func _has_own_menu(control: Control) -> bool:
	if control.has_meta(OWN_CONTEXT_MENU):
		return true
	if control is LineEdit:
		return (control as LineEdit).context_menu_enabled
	if control is TextEdit:
		return (control as TextEdit).context_menu_enabled
	if control is RichTextLabel:
		return (control as RichTextLabel).context_menu_enabled
	return false


#* Open a popup below an anchor (above if it can't fit):
#? anchor: the control's rect, in screen coordinates.
static func popup_at(popup: Popup, anchor: Rect2i, host: Control) -> void:
	#? Pass the whole rect - given a position only, Godot fits the popup below it with a scrollbar.
	popup.popup(solve_rect(popup, anchor, host))


#* Open a popup beside an anchor across, but centered on the screen up and down (tall popups):
#? anchor: the control's rect, in screen coordinates.
static func popup_centered_vertically(popup: Popup, anchor: Rect2i, host: Control) -> void:
	var rect := solve_rect(popup, anchor, host)
	var screen := DisplayServer.screen_get_usable_rect()
	if host != null and host.get_window() != null:
		screen = DisplayServer.screen_get_usable_rect(host.get_window().current_screen)
	#% No screen known (headless): as popup_at() places it:
	if screen.size.y > 0:
		rect.size.y = mini(rect.size.y, screen.size.y)
		rect.position.y = screen.position.y + int((screen.size.y - rect.size.y) * 0.5)
	popup.popup(rect)


static func popup_at_point(popup: Popup, point: Vector2i, host: Control) -> void:
	popup_at(popup, Rect2i(point, Vector2i.ZERO), host)


#* Fix a MenuButton's or OptionButton's own popup placement:
static func attach_button_popup(button: Button) -> void:
	var popup = button.get_popup()
	#? About_to_popup runs after the button placed it, so this gets the last word.
	popup.about_to_popup.connect(func():
		var anchor := Rect2i(Vector2i(button.get_screen_position()), Vector2i(button.size))
		var rect := solve_rect(popup, anchor, button)
		popup.position = rect.position
		popup.size = rect.size)


#* Show at most `rows` items of a menu, scrolling the rest:
static func limit_rows(menu: PopupMenu, rows: int) -> void:
	#? Measured on each opening (later items count), with the menu's own theme.
	menu.about_to_popup.connect(func():
		if menu.item_count <= rows:
			menu.max_size.y = 0
			return
		#Ł Measure the first rows like PopupMenu, inside the panel's margins:
		#? Not get_contents_minimum_size(), which PopupMenu caps at the screen's height.
		var height := menu.get_theme_stylebox(&"panel").get_minimum_size().y
		var gap := menu.get_theme_constant(&"v_separation")
		for i in rows:
			height += _item_height(menu, i) + gap
		menu.max_size.y = ceili(height))


#* Height PopupMenu draws an item at (v_separation aside):
static func _item_height(menu: PopupMenu, index: int) -> float:
	if menu.is_item_separator(index):
		var line := menu.get_theme_stylebox(&"separator").get_minimum_size().y
		line = maxf(line, menu.get_theme_stylebox(&"labeled_separator_left").get_minimum_size().y)
		line = maxf(line, menu.get_theme_stylebox(&"labeled_separator_right").get_minimum_size().y)
		if menu.get_item_text(index) == "":
			return line
		var separator_font := menu.get_theme_font(&"font_separator")
		return maxf(line, separator_font.get_height(menu.get_theme_font_size(&"font_separator_size")))
	var item := menu.get_theme_font(&"font").get_height(menu.get_theme_font_size(&"font_size"))
	var icon := menu.get_item_icon(index)
	if icon != null:
		item = maxf(item, icon.get_height())
	if menu.is_item_checkable(index) or menu.is_item_radio_checkable(index):
		item = maxf(item, menu.get_theme_icon(&"checked").get_height())
		item = maxf(item, menu.get_theme_icon(&"radio_checked").get_height())
	return item


#* Keep a popup placed by something else inside the window:
static func attach_clamp(popup: Popup, host: Control) -> void:
	popup.about_to_popup.connect(func():
		var rect := solve_rect(popup, Rect2i(popup.position, Vector2i.ZERO), host)
		popup.position = rect.position
		popup.size = rect.size)


#* Popup rect - below the anchor, above if it overflows the window, clamped if neither fits:
static func solve_rect(popup: Popup, anchor: Rect2i, host: Control) -> Rect2i:
	var bounds := _bounds(host)
	var size := _size_of(popup)
	#? Only a menu taller than the window scrolls.
	size.y = mini(size.y, bounds.size.y)
	size.x = mini(size.x, bounds.size.x)

	var position := Vector2i(anchor.position.x, anchor.position.y + anchor.size.y)
	if position.y + size.y > bounds.end.y:
		var above := anchor.position.y - size.y
		if above >= bounds.position.y:
			position.y = above
		else:
			#% Fits neither way - show as much as possible:
			position.y = maxi(bounds.position.y, bounds.end.y - size.y)

	position.x = clampi(position.x, bounds.position.x, maxi(bounds.position.x, bounds.end.x - size.x))
	return Rect2i(position, size)


static func solve(popup: Popup, anchor: Rect2i, host: Control) -> Vector2i:
	return solve_rect(popup, anchor, host).position


#* The popup's wanted size:
static func _size_of(popup: Popup) -> Vector2i:
	#Ł Size to contents - popup.size is zero before the first show, then the last height:
	popup.reset_size()
	var minimum := popup.get_contents_minimum_size()
	var result := Vector2i(maxi(popup.size.x, int(minimum.x)), maxi(popup.size.y, int(minimum.y)))
	#% A menu limited by limit_rows() is no taller than that:
	if popup.max_size.y > 0:
		result.y = mini(result.y, popup.max_size.y)
	return result


#* The control's window, trimmed to its screen's usable area:
static func _bounds(host: Control) -> Rect2i:
	var window: Window = null
	if host != null:
		window = host.get_window()
	if window == null:
		return DisplayServer.screen_get_usable_rect()

	var rect := Rect2i(window.position, window.size)
	var screen := DisplayServer.screen_get_usable_rect(window.current_screen)
	if rect.intersects(screen):
		return rect.intersection(screen)
	return rect