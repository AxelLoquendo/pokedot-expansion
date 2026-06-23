extends Resource

class_name AbilityData

@export var ability_id: Abilities.AbilityId
@export var ability_name: String
@export_multiline var ability_description: String

@export var ai_rating: int = 0

# Restrictions

@export var cant_be_copied := false
@export var cant_be_swapped := false
@export var cant_be_traced := false
@export var cant_be_suppressed := false
@export var cant_be_overwritten := false

# Mechanics
@export var can_breakable := false
@export var fails_on_imposter := false

# Actual effect

@export var effect: AbilityStruct.AbilityEffect
