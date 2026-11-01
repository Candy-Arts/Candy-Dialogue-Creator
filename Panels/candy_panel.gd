#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPanel
extends Control

#^ Set by the host before the panel enters the tree:
var area_id: int = -1
var window_id: String = ""
#^ Set by the host - whether the panel fills its Area:
#? False in a Tabs panel's tab, which has no minimum size of its own.
var fills_area := false


#* Return the data that restores this panel (scroll, zoom, selection...):
#? Saved with var_to_str(): built-in types, Color included, no Objects.
func get_state() -> Dictionary:
	return {}


#* Restore a saved state:
#? Called before _ready(), only when one exists.
func set_state(_state: Dictionary) -> void:
	pass


#* Whether this panel has settings:
#? True: "Options" calls open_settings(). False: the Area's "Options" only offers its size limits.
#? The settings dialog ends with the minimum size (when fills_area): area_size_limits() / set_area_size_limits().
func has_settings() -> bool:
	return false


#* Open this panel's settings dialog:
func open_settings() -> void:
	pass


#* Run "Options", from any menu that offers it:
func open_panel_settings() -> void:
	if has_settings():
		open_settings()
	elif fills_area:
		CandyMinSizeDialog.open_for_area(self, window_id, area_id)


#* Whether open_panel_settings() has anything to open:
func can_open_panel_settings() -> bool:
	return has_settings() or fills_area


#* Return this panel's Area's size limits (CandyMinSizeFields.limits_of(), all 0 when it fills none):
func area_size_limits() -> Dictionary:
	var config := {}
	if fills_area:
		var area := CandyLayout.find_area(window_id, area_id)
		if area != null:
			config = area.config
	return CandyMinSizeFields.limits_of(config)


#* Store this panel's Area's size limits:
func set_area_size_limits(limits: Dictionary) -> void:
	if not fills_area or limits == area_size_limits():	#/ Unchanged: a change rebuilds the window's view
		return
	CandyLayout.set_area_size_limits(window_id, area_id, limits)


#* Return extra entries for the Area's and tab's menus, under "Options":
#? The chosen one goes to run_area_action().
func get_area_actions() -> PackedStringArray:
	return PackedStringArray()


#* Run an entry of get_area_actions():
func run_area_action(_action: String) -> void:
	pass