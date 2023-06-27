extends Node

export(Array) var items = [
	preload("res://common/singletons/items/coin/coin.tres"),
	preload("res://common/singletons/items/gem/gem.tres"),
	preload("res://common/singletons/items/picoberry/picoberry.tres"),
	preload("res://common/singletons/items/invisiberry/invisiberry.tres"),
	preload("res://common/singletons/items/magnet/magnet.tres"),
	preload("res://common/singletons/items/laser/laser.tres"),
	preload("res://common/singletons/items/boost/boost.tres"),
]


func pick_item_id() -> int:
	var index = randi() % items.size()
	return index


func get_item(id: int) -> Item:
	if id >= items.size():
		push_error("Item ID %d doesn't exist! Max ID = %d" % [id, items.size()])
		return null
	return items[id]
