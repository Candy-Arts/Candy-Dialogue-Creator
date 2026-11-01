#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationSelection
extends RefCounted

signal changed(variation_reference: String, variation_name: String)
#^ A Speech Editor's text changed, with its variation:
signal text_typed(variation_name: String, text: String)

const DEFAULT_REFERENCE := "1"
const DEFAULT_VARIATION := "Default"

var _selected: Dictionary = {}       #/ reference -> variation name


func get_selected(variation_reference: String) -> String:
	return str(_selected.get(_clean(variation_reference), DEFAULT_VARIATION))


func select(variation_reference: String, variation_name: String) -> void:
	var key := _clean(variation_reference)
	if str(_selected.get(key, "")) == variation_name:
		return
	_selected[key] = variation_name
	changed.emit(key, variation_name)


func publish_typed(variation_name: String, text: String) -> void:
	text_typed.emit(variation_name, text)


func _clean(variation_reference: String) -> String:
	var text := variation_reference.strip_edges()
	if text == "":
		return DEFAULT_REFERENCE
	return text
