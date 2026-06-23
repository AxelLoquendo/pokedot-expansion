extends RefCounted

class_name pokemon

var species : PokemonDataStruct

var level: int
var experience: int

var iv_hp: int
var iv_attack: int
var iv_defense: int
var iv_speed: int
var iv_sp_attack: int
var iv_sp_defense: int

var nature: PokemonData.Nature

var current_hp: int

var moves: Array[MoveData]
