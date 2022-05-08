extends Object
class_name Logger

enum Actions {
	UndoClicked = 14,
	UpgradeMenuClicked = 17,
	UpgradeMenuBackClicked = 18,
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
	
	func log_level_start(level_id: int, details=null) -> void:
		if not self.enabled:
			return
		self._logger.logLevelStart(level_id, details)
	
	func log_level_end(details=null) -> void:
		if not self.enabled:
			return
		self._logger.logLevelEnd(details)
	
	func log_level_action(action_id: int, details=null) -> void:
		if not self.enabled:
			return
		self._logger.logLevelAction(action_id, details)
	
	func log_action_with_no_level(action_id: int, details=null) -> void:
		if not self.enabled:
			return
		self._logger.logActionWithNoLevel(action_id, details)
	
	func flush_buffered_level_actions() -> void:
		if not self.enabled:
			return
		self._logger.flushBufferedLevelActions()
