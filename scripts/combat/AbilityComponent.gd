extends Node
class_name AbilityComponent

signal ability_requested(slot: int)

@export var enabled_slots := 0

func can_activate(slot: int) -> bool:
	return slot >= 0 and slot < enabled_slots

func request_activate(slot: int) -> bool:
	if not can_activate(slot):
		return false
	ability_requested.emit(slot)
	return true
