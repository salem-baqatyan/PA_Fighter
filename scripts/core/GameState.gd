extends RefCounted
class_name GameState

enum Phase {
	BOOT,
	LOBBY,
	CHARACTER_SELECTION,
	WAITING_FOR_PLAYER,
	MATCH_START,
	PLAYING,
	PLAYER_DEAD,
	RESPAWNING,
	VICTORY,
	DEFEAT,
	RETURN_TO_LOBBY
}

const RED := "red"
const BLUE := "blue"
const SWORD := "sword"
const BOXER := "boxer"
