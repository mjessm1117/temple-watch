extends GdUnitTestSuite

const Mission = preload("res://scripts/mission.gd")
const Chains = preload("res://scripts/ability_chains.gd")

func test_mission_has_player_and_enemy() -> void:
	var mission = Mission.new(17)
	assert_bool(not mission.living("player").is_empty()).is_true()
	assert_bool(not mission.living("enemy").is_empty()).is_true()

func test_chain_tag_can_be_applied() -> void:
	var mission = Mission.new(17)
	var enemy: Dictionary = mission.living("enemy")[0]
	Chains.apply_tag(enemy, "MARKED")
	assert_bool(Chains.has_tag(enemy, "MARKED")).is_true()
