class_name PokemonSprite
extends RefCounted


var sprite2d: Sprite2D

func _init(pokemon_id: String, is_opponent: bool, sprite2d) -> void:
  sprite2d = sprite2d
  sprite2d.texture = load("res://graphics/pokemon/back/000.png")

func update_statbar(pokemon: Pokemon, update_prevhp: bool=false, update_hp: bool=false) -> void:
  # TODO
  pass