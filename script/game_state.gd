extends Node
## Persists across scene changes: tracks the player's run so the
## win/lose screens can tell a story that actually reflects what happened.

const DAY_LENGTH := 45.0 # seconds of survival time per in-game "day"
const TREES_NEEDED := 40

var wood_collected: int = 0
var food_gathered: int = 0
var survival_time: float = 0.0
var has_boat: bool = false
var death_cause: String = "" # "starvation", "exposure", or "" if not dead

func reset() -> void:
	wood_collected = 0
	food_gathered = 0
	survival_time = 0.0
	has_boat = false
	death_cause = ""

func get_day() -> int:
	return int(survival_time / DAY_LENGTH) + 1

## A short line describing how thorough the player's survival run was,
## used to flavor the win screen.
func get_performance_line() -> String:
	if wood_collected >= TREES_NEEDED + 15:
		return "You leave nothing to chance, hauling far more wood than the raft needed."
	elif wood_collected >= TREES_NEEDED:
		return "You built the raft with exactly what the island would spare."
	return "You built the raft with whatever the island would give you."

func get_death_line() -> String:
	match death_cause:
		"starvation":
			return "Your strength finally gave out. The island keeps its dead."
		"exposure":
			return "The cold and the hunger wore you down together."
		_:
			return "The island claims another castaway."
