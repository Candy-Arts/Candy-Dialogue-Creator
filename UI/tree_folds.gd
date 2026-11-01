#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTreeFolds


#* Add the fold state of every item with children:
static func remember(tree: Tree, folds: Dictionary) -> void:
	var root := tree.get_root()
	if root != null:
		_remember_children(root, "", folds)


#* Fold or unfold the known items (others keep their built state):
static func restore(tree: Tree, folds: Dictionary) -> void:
	var root := tree.get_root()
	if root != null:
		_restore_children(root, "", folds)


static func _remember_children(parent: TreeItem, prefix: String, folds: Dictionary) -> void:
	for item in parent.get_children():
		if item.get_child_count() == 0:
			continue
		var key := prefix + item.get_text(0)
		folds[key] = item.collapsed
		_remember_children(item, key + "/", folds)


static func _restore_children(parent: TreeItem, prefix: String, folds: Dictionary) -> void:
	for item in parent.get_children():
		var key := prefix + item.get_text(0)
		if folds.has(key):
			item.collapsed = bool(folds[key])
		_restore_children(item, key + "/", folds)
