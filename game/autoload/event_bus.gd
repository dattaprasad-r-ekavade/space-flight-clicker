extends Node

signal revenue_changed(value: float)
signal division_changed(id: String)
signal launch_started(id: String)
signal launch_finished(id: String, revenue: float, apogee: float)
signal stage_unlocked(id: String)
signal record_height_changed(value: float)
signal prestige_done(echoes_gained: int)
signal boost_changed()
signal state_loaded()
## Ask the UI to show a short message. Core code and GameState must use this; they must never name a UI class.
signal toast_requested(text: String)
