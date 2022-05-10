extends Node2D
class_name Upgrade

export(Dictionary) var cost
export(String) var upgrade_name
export(String) var description
export(String) var effects

var purchased : bool = false

func _ready():
	assert(cost != null)
	assert(upgrade_name != null)
	assert(description != null)
	assert(effects != null)

"""
	Purchase the upgrade, spending its resource cost. If the purchase succeeds,
	execute apply(). Otherwise (if the upgrade has already been purchased, or
	there are not enough resources to purchase it), do nothing.
"""
func purchase():
	if not purchased and GameStats.resources.try_consume(cost):
		purchased = true
		apply()
	else:
		return false

"""
	Apply the upgrade
"""
func apply():
	pass
