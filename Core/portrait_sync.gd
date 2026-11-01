#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPortraitSync
extends RefCounted

#^ The voice started or resumed at seconds:
signal played(seconds: float)
signal paused
#^ The voice stopped, back at its start (the portrait too):
signal stopped
#^ The voice reached its end (not a stop - the portrait carries on, as in game):
signal finished
#^ The voice was moved to seconds (seek bar):
signal sought(seconds: float)


func play(seconds: float) -> void:
	played.emit(seconds)


func pause() -> void:
	paused.emit()


func stop() -> void:
	stopped.emit()


func finish() -> void:
	finished.emit()


func seek(seconds: float) -> void:
	sought.emit(seconds)
