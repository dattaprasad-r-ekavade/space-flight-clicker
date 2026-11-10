extends Node
## Analytics entry point. Sends events to the current provider.

const EVENT_SESSION_START: String = "session_start"
const EVENT_TUTORIAL_STEP: String = "tutorial_step"
const EVENT_STAGE_UNLOCKED: String = "stage_unlocked"
const EVENT_MANAGER_HIRED: String = "manager_hired"
const EVENT_PRESTIGE: String = "prestige"
const EVENT_AD_OFFERED: String = "ad_offered"
const EVENT_AD_SHOWN: String = "ad_shown"
const EVENT_AD_REWARDED: String = "ad_rewarded"
const EVENT_OFFLINE_CLAIM: String = "offline_claim"
const EVENT_DAILY_CLAIM: String = "daily_claim"
const EVENT_CONTRACT_DONE: String = "contract_done"

var provider: AnalyticsProvider = null


func _ready() -> void:
	if provider == null:
		provider = LogAnalyticsProvider.new()
	if not is_inside_tree():
		return
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.stage_unlocked.connect(_on_stage_unlocked)
		bus.prestige_done.connect(_on_prestige_done)
	var gs: Node = get_node_or_null("/root/GameState")
	var life: int = 1
	if gs != null:
		life = int(gs.get("life"))
	event(EVENT_SESSION_START, {"life": life})


func set_provider(p: AnalyticsProvider) -> void:
	provider = p


func event(name: String, params: Dictionary = {}) -> void:
	if provider == null:
		return
	provider.log_event(name, params)


func _on_stage_unlocked(id: String) -> void:
	event(EVENT_STAGE_UNLOCKED, {"id": id})


func _on_prestige_done(echoes_gained: int) -> void:
	event(EVENT_PRESTIGE, {"echoes_gained": echoes_gained})
