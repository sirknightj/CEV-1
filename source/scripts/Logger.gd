extends Object
class_name Logger

enum Actions {
	NextMonthClicked = 12,
	UndoClicked = 14,
	UpgradeMenuClicked = 17,
	UpgradeMenuBackClicked = 18,
	UpgradeBought = 32,
	UpgradeClickOn = 35,
	UpgradeClickOff = 36,

	BuildingGrabbed = 60,
	BuildingPlaced = 61,
	BuildingReleased = 62,
	BuildingDeleted = 63,
	BuildingDisabled = 64,

	BuildingRotated = 70,
	BuildingFlipped = 71,
}

class Log:
	var _logger
	var enabled: bool
	
	func _init() -> void:
		self.enabled = OS.has_feature('JavaScript')
		if self.enabled:
			print("Has JavaScript support, enabling logging")
		else:
			print("No JavaScript support, disabling logging")
	
	func start_new_session(category_id: int) -> void:
		if not self.enabled:
			return
		self._logger = JavaScript.get_interface("window").getLogger(category_id)
		self._logger.startNewSession()
	
	func log_level_start(level_id: int, details: Dictionary={}) -> void:
		if not self.enabled:
			return
		var j = JSON.print(details) if details.size() else null
		self._logger.logLevelStart(level_id, j)
	
	func log_level_end(details: Dictionary={}) -> void:
		if not self.enabled:
			return
		var j = JSON.print(details) if details.size() else null
		self._logger.logLevelEnd(j)
	
	func log_level_action(action_id: int, details: Dictionary={}) -> void:
		if not self.enabled:
			return
		var j = JSON.print(details) if details.size() else null
		self._logger.logLevelAction(action_id, j)
	
	#func log_action_with_no_level(action_id: int, details: Dictionary={}) -> void:
	#	if not self.enabled:
	#		return
	#	var j = JSON.print(details) if details.size() else null
	#	self._logger.logActionWithNoLevel(action_id, j)
	
	func flush_buffered_level_actions() -> void:
		if not self.enabled:
			return
		self._logger.flushBufferedLevelActions()
