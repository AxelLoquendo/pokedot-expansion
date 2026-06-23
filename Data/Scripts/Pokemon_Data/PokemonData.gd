extends RefCounted

class_name PokemonData

#Pokémon Types
enum Type {
	TYPE_NONE,
	TYPE_NORMAL,
	TYPE_FIGHTING,
	TYPE_FLYING,
	TYPE_POISON,
	TYPE_GROUND,
	TYPE_ROCK,
	TYPE_BUG,
	TYPE_GHOST,
	TYPE_STEEL,
	TYPE_MYSTERY,
	TYPE_FIRE,
	TYPE_WATER,
	TYPE_GRASS,
	TYPE_ELECTRIC,
	TYPE_PSYCHIC,
	TYPE_ICE,
	TYPE_DRAGON,
	TYPE_DARK,
	TYPE_FAIRY,
	TYPE_STELLAR
}
# Grupos Huevos
enum EggGroup {
	EGG_GROUP_NONE,
	EGG_GROUP_MONSTER,
	EGG_GROUP_WATER_1,
	EGG_GROUP_BUG,
	EGG_GROUP_FLYING,
	EGG_GROUP_FIELD,
	EGG_GROUP_FAIRY,
	EGG_GROUP_GRASS,
	EGG_GROUP_HUMAN_LIKE,
	EGG_GROUP_WATER_3,
	EGG_GROUP_MINERAL,
	EGG_GROUP_AMORPHOUS,
	EGG_GROUP_WATER_2,
	EGG_GROUP_DITTO,
	EGG_GROUP_DRAGON,
	EGG_GROUP_NO_EGGS_DISCOVERED,
}
const EGG_GROUPS_PER_MON := 2
#Naturalezas Pokemon
enum Nature {
	NATURE_HARDY,    # Neutral
	NATURE_LONELY,   # +Atk -Def
	NATURE_BRAVE,    # +Atk -Speed
	NATURE_ADAMANT,  # +Atk -SpAtk
	NATURE_NAUGHTY,  # +Atk -SpDef
	NATURE_BOLD,     # +Def -Atk
	NATURE_DOCILE,   # Neutral
	NATURE_RELAXED,  # +Def -Speed
	NATURE_IMPISH,   # +Def -SpAtk
	NATURE_LAX,      # +Def -SpDef
	NATURE_TIMID,    # +Speed -Atk
	NATURE_HASTY,    # +Speed -Def
	NATURE_SERIOUS,  # Neutral
	NATURE_JOLLY,    # +Speed -SpAtk
	NATURE_NAIVE,    # +Speed -SpDef
	NATURE_MODEST,   # +SpAtk -Atk
	NATURE_MILD,     # +SpAtk -Def
	NATURE_QUIET,    # +SpAtk -Speed
	NATURE_BASHFUL,  # Neutral
	NATURE_RASH,     # +SpAtk -SpDef
	NATURE_CALM,     # +SpDef -Atk
	NATURE_GENTLE,   # +SpDef -Def
	NATURE_SASSY,    # +SpDef -Speed
	NATURE_CAREFUL,  # +SpDef -SpAtk
	NATURE_QUIRKY,   # Neutral
}

const NUM_NATURES := 25
const NATURE_RANDOM := NUM_NATURES
const NATURE_MAY_SYNCHRONIZE := NUM_NATURES + 1

enum OtIdMethod
{
	OT_ID_PLAYER_ID,
	OT_ID_PRESET,
	OT_ID_RANDOM_NO_SHINY
}

# Growth Rates
enum GrowthRate {
	GROWTH_MEDIUM_FAST,
	GROWTH_ERRATIC,
	GROWTH_FLUCTUATING,
	GROWTH_MEDIUM_SLOW,
	GROWTH_FAST,
	GROWTH_SLOW,
}
# Body colors for Pokédex search (epa, soy bilingue, oño xd)
enum BodyColor {
	BODY_COLOR_RED,
	BODY_COLOR_BLUE,
	BODY_COLOR_YELLOW,
	BODY_COLOR_GREEN,
	BODY_COLOR_BLACK,
	BODY_COLOR_BROWN,
	BODY_COLOR_PURPLE,
	BODY_COLOR_GRAY,
	BODY_COLOR_WHITE,
	BODY_COLOR_PINK,
}
# Condicion para las evoluciones
enum EvolutionConditions {
	NONE,                               #Ninguna Condicion
	#Gen 2
	IF_GENDER,                          # The Pokémon is of specific gender.
	IF_TIME,                            # It is currently the specific time of day.
	IF_NOT_TIME,                        # It is NOT currently the specific time of day.
	IF_MIN_FRIENDSHIP,                  # The Pokémon has the defined amount of Friendship.
	IF_ATK_GT_DEF,                      # The Pokémon's Attack is greater than its Defense stat.
	IF_ATK_EQ_DEF,                      # The Pokémon's Attack is equal to its Defense stat.
	IF_ATK_LT_DEF,                      # The Pokémon's Attack is lower than its Defense stat.
	IF_HOLD_ITEM,                       # The Pokémon is holding a specific item.
	# Gen 3
	IF_PID_UPPER_MODULO_10_GT,          # The Pokémon's upper personality value's modulo by 10 is greater than the defined value.
	IF_PID_UPPER_MODULO_10_EQ,          # The Pokémon's upper personality value's modulo by 10 is equal to the defined value.
	IF_PID_UPPER_MODULO_10_LT,          # The Pokémon's upper personality value's modulo by 10 is lower or equal than the defined value.
	IF_MIN_BEAUTY,                      # The Pokémon has the defined amount of Beauty.
	IF_MIN_COOLNESS,                    # The Pokémon has the defined amount of Coolness.
	IF_MIN_SMARTNESS,                   # The Pokémon has the defined amount of Smartness. (aka Cleverness in Gen6+)
	IF_MIN_TOUGHNESS,                   # The Pokémon has the defined amount of Toughness.
	IF_MIN_CUTENESS,                    # The Pokémon has the defined amount of Cuteness.
	# Gen 4
	IF_SPECIES_IN_PARTY,                # The party contains a Pokémon of the specified species.
	IF_IN_MAP,                          # The player is currently in the specific map.
	IF_IN_MAPSEC,                       # The player is currently in the specific map sector.
	IF_KNOWS_MOVE,                      # The Pokémon knows specific move.
	# Gen 5
	IF_TRADE_PARTNER_SPECIES,           # The Pokémon is traded for a specific species.
	# Gen 6
	IF_TYPE_IN_PARTY,                   # The party contains a Pokémon of the specified type.
	IF_WEATHER,                         # It is currently the specific weather in the current map.
	IF_KNOWS_MOVE_TYPE,                 # The Pokémon knows a move with a specific type.
	# Gen 8
	IF_NATURE,                          # The Pokémon has a specific nature.
	IF_AMPED_NATURE,                    # The Pokémon has one of the following natures: Hardy, Brave, Adamant, Naughty, Docile, Impish, Lax, Hasty, Jolly, Naive, Rash, Sassy, or Quirky.
	IF_LOW_KEY_NATURE,                  # The Pokémon has one of the following natures: Lonely, Bold, Relaxed, Timid, Serious, Modest, Mild, Quiet, Bashful, Calm, Gentle, or Careful.
	IF_RECOIL_DAMAGE_GE,                # The Pokémon suffered at least certain amount of non-fainting recoil damage.
	IF_CURRENT_DAMAGE_GE,               # The Pokémon has the specified difference of HP from its Max HP.
	IF_CRITICAL_HITS_GE,                # The Pokémon performed the specified number of critical hits in one battle at least.
	IF_USED_MOVE_X_TIMES,               # The Pokémon has used a move for at least X amount of times.
	# Gen 9
	IF_DEFEAT_X_WITH_ITEMS,             # The Pokémon defeated X amount of Pokémon of the specified species that are holding the specified item.
	IF_PID_MODULO_100_GT,               # The Pokémon's personality value's modulo by 100 is greater than the defined value.
	IF_PID_MODULO_100_EQ,               # The Pokémon's personality value's modulo by 100 is equal than the defined value.
	IF_PID_MODULO_100_LT,               # The Pokémon's personality value's modulo by 100 is lower than the defined value.
	IF_MIN_OVERWORLD_STEPS,             # The Player has taken a specific amount of steps in the overworld with the Pokémon following them or in the first slot of the party.
	IF_BAG_ITEM_COUNT,                  # The Player has the specific amount of an item in the bag. It then removes those items.
	IF_REGION,                          # The Player is in the specific region.
	IF_NOT_REGION,                      # The Player is NOT in the specific region.
}
static var CONDITIONS_END := EvolutionConditions.size()
# metodos evolutivos
enum EvolutionMethods {
	EVO_NONE,                   # Not an actual evolution, used to generate offspring that can't evolve into the specified species, like regional forms.
	EVO_LEVEL,                  # Pokémon reaches the specified level
	EVO_TRADE,                  # Pokémon is traded
	EVO_ITEM,                   # specified item is used on Pokémon
	EVO_SPLIT_FROM_EVO,         # A clone is generated and evolved when another evolution happens
	EVO_SCRIPT_TRIGGER,         # Player interacts with an overworld trigger
	EVO_LEVEL_BATTLE_ONLY,      # Pokémon reaches the specified level, in battle only
	EVO_BATTLE_END,             # Battle ends, doesn't need to level up
	EVO_SPIN                    # The player spins in the overworld
}
# modo de evolucion
enum EvolutionMode {
	EVO_MODE_NORMAL,
	EVO_MODE_TRADE,
	EVO_MODE_ITEM_USE,
	EVO_MODE_ITEM_CHECK,         # If an Everstone is being held, still want to show that the stone *could* be used on that Pokémon to evolve
	EVO_MODE_BATTLE_SPECIAL,
	EVO_MODE_OVERWORLD_SPECIAL,
	EVO_MODE_SCRIPT_TRIGGER,
	EVO_MODE_BATTLE_ONLY,        # This mode is only used in battles to support Tandemaus' unique requirement
}
# estado de evolucion
enum EvoState {
	CHECK_EVO,
	DO_EVO,
}

enum EvoSpinDirections {
	SPIN_CW_SHORT,              # Player spins clockwise
	SPIN_CW_LONG,               # Player spins clockwise
	SPIN_CCW_SHORT,             # Player spins counter-clockwise
	SPIN_CCW_LONG,              # Player spins counter-clockwise
	SPIN_EITHER,                # Player spins either clockwise or counter-clockwise
}

enum ShinyMode {
	SHINY_MODE_ALWAYS,
	SHINY_MODE_RANDOM,
	SHINY_MODE_NEVER
}

enum GenderRatio {
	GENDER_FEMALE_100,
	GENDER_FEMALE_87_5,
	GENDER_FEMALE_75,
	GENDER_FEMALE_50,
	GENDER_FEMALE_25,
	GENDER_FEMALE_12_5,
	GENDER_MALE_100,
	GENDER_GENDERLESS
}
