class_name StageUnlockWatcher
extends Control
## Listens for stage_unlocked and shows the stage-unlock popup. Attached by main.gd.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.stage_unlocked.connect(_on_stage_unlocked)


func _on_stage_unlocked(id: String) -> void:
	if PopupHost.instance == null:
		return
	var popup: PopupStageUnlock = PopupStageUnlock.new()
	popup.setup(id)
	PopupHost.instance.show_popup(popup)
