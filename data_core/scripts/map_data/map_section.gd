extends RefCounted

class_name MapSections

enum SectionID {
	MAPSEC_NONE,
	# Region Valtherion
	MAPSEC_PRADO_NATAL,
	MAPSEC_PUEBLO_ALBA
}

enum RegionId {
	REGION_NONE,
	REGION_VALTHERION,
	REGION_KANTO,
	REGION_JOHTO,
	REGION_HOENN,
	REGION_SINNOH,
	REGION_UNOVA,
	REGION_KALOS,
	REGION_ALOLA,
	REGION_GALAR,
	REGION_PALDEA,
}

const SECTION_TO_SCENE: Dictionary = {
	SectionID.MAPSEC_PRADO_NATAL: "res://data_core/maps/prado_natal/prado_natal.tscn",
	SectionID.MAPSEC_PUEBLO_ALBA: "res://data_core/maps/pueblo_alba/pueblo_alba.tscn",
	# Agrega aquí todos tus mapas para enlazarlos con sus IDs
}
