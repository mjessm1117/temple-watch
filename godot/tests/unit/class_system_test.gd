extends GdUnitTestSuite

const Classes = preload("res://scripts/class_registry.gd")

func test_class_schemas_validate() -> void:
	assert_bool(Classes.validate().is_empty()).is_true()

func test_all_classes_load() -> void:
	assert_int(Classes.classes().size()).is_equal(15)
