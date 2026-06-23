extends Resource

class_name PokemonDataStruct

# Species
@export_group("Species")
@export var national_dex_number: int
@export var species_name: String
@export var species_id: Species.SpeciesId

# Base Stats
@export_group("Base Stats")
@export var base_hp: int
@export var base_attack: int
@export var base_defense: int
@export var base_speed: int
@export var base_sp_attack: int
@export var base_sp_defense: int

# Types
@export_group("Types")
@export var type_1: PokemonData.Type
@export var type_2: PokemonData.Type = PokemonData.Type.TYPE_NONE

# General Data
@export_group("General Data")
@export var catch_rate: int
@export var exp_yield: int
@export var friendship: int
@export var growth_rate: PokemonData.GrowthRate

# Pokédex
@export_group("Pokédex")
@export var category_name: String
@export_multiline var description: String
@export var height: int
@export var weight: int
@export var body_color: PokemonData.BodyColor

# Graphics
@export_group("Graphics")
@export var front_sprite: Texture2D
@export var front_sprite_shiny: Texture2D
@export var back_sprite: Texture2D
@export var back_sprite_shiny: Texture2D
@export var icon_sprite: Texture2D
@export var overworld_scene: Texture2D

# Learnsets
@export_group("Learnsets")
@export var level_up_moves: Array[LevelUpMove]
@export var teachable_moves: Array[Moves.MoveId]
@export var egg_moves: Array[Moves.MoveId]

# Evolution
@export_group("Evolutions")
@export var evolutions: Array[EvolutionData]

# Abilities
@export_group("Abilities")
@export var ability_1: Abilities.AbilityId
@export var ability_2: Abilities.AbilityId
@export var hidden_ability: Abilities.AbilityId

# Items
@export_group("Items")
@export var item_common: Items.ItemId
@export var item_rare: Items.ItemId

# Flags
@export_group("Flags")
@export var is_legendary := false
@export var is_mythical := false
@export var is_ultra_beast := false

# Breeding
@export_group("Breeding")
@export var egg_group_1: PokemonData.EggGroup
@export var egg_group_2: PokemonData.EggGroup
@export var egg_cycles: int
@export var hatch_species: Species.SpeciesId

# Battle Position
@export_group("Battle Position")
@export var front_sprite_offset: Vector2
@export var back_sprite_offset: Vector2

# Gender
@export_group("Gender")
@export var gender_ratio: PokemonData.GenderRatio

# cry
@export_group("cry")
@export var cry: AudioStream
