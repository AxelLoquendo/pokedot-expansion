extends Resource

class_name ItemData

@export var item_id: Items.ItemId
@export var secondary_id: int = 0

@export var item_name: String
@export var plural_name: String
@export_multiline var item_description: String

@export var price: int = 0

@export var pocket: ItemStruct.Pocket
@export var item_type: ItemStruct.ItemType

@export var hold_effect: ItemStruct.HoldEffect
@export var hold_effect_param: int = 0

@export var battle_usage: ItemStruct.BattleUsage
@export var fling_power: int = 0

@export var importance := false
@export var not_consumed := false

@export var icon: Texture2D

# efecto real del objeto
@export var effect: ItemStruct.ItemEffect
