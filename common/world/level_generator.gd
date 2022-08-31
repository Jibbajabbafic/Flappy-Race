extends Node

tool

class_name LevelGenerator


export(Array) var Obstacles
export(PackedScene) var FinishLine


var game_rng: RandomNumberGenerator
var obstacle_spacing := 500
var obstacle_start_pos := 1500
var generated_obstacles := []
var spawned_obstacles := {}
var finish_line: Node2D


signal level_ready


func _ready() -> void:
	if Engine.is_editor_hint():
		# Preview a level in the editor
		game_rng = RandomNumberGenerator.new()
		game_rng.randomize()
		generate(game_rng, 10)


func generate(rng: RandomNumberGenerator, obstacles_to_generate: int) -> void:
	Logger.print(self, "Generating level with %d obstacles..." % obstacles_to_generate)
	game_rng = rng
	clear_obstacles()
	var next_obstacle_pos := obstacle_start_pos
	var start = OS.get_ticks_usec()
	# -1 to account for the finish line
	for i in obstacles_to_generate - 1:
		var obstacle := generate_obstacle()
		obstacle.set_name("%s_%d" % [obstacle.name, i])
		obstacle.position.x = next_obstacle_pos
		generated_obstacles.append(obstacle)
		next_obstacle_pos += obstacle.calculate_length() + obstacle_spacing
	# Finish line is always the final obstacle
	finish_line = FinishLine.instance()
	finish_line.position.x = next_obstacle_pos
	generated_obstacles.append(finish_line)
	var end = OS.get_ticks_usec()
	var generation_time = (end-start) / 1000
	Logger.print(self, "Obstacles generated in %dms!" % generation_time)
	emit_signal("level_ready")


func clear_obstacles() -> void:
	for obst in generated_obstacles:
		obst.queue_free()
	generated_obstacles.clear()
	for obst in spawned_obstacles:
		obst.queue_free()
	spawned_obstacles.clear()


func generate_obstacle() -> Obstacle:
	assert(game_rng != null)
	assert(Obstacles.size() > 0)
	# Use the game RNG to keep the levels deterministic
	var index = game_rng.randi_range(0, Obstacles.size() - 1)
	var obstacle = Obstacles[index].instance()
	obstacle.generate(game_rng)
	return obstacle


func spawn_obstacle(obstacle_index: int) -> void:
	if obstacle_index >= generated_obstacles.size():
		push_error("Tried spawning obstacle %d but only %d were generated!" % [obstacle_index, generated_obstacles.size()])
		return
	if spawned_obstacles.has(obstacle_index):
		# Obstacle already spawned
		return
	var obstacle = generated_obstacles[obstacle_index]
	spawned_obstacles[obstacle_index] = obstacle
	Logger.print(self, "Spawning %s at %s", [obstacle.name, obstacle.position])
	# Defer because we can't spawn areas during a collision notification
	call_deferred("add_child", obstacle)


func despawn_obstacle(obstacle_index: int) -> void:
	if not spawned_obstacles.has(obstacle_index):
		push_error("Tried despawning obstacle %d but it hasn't been spawned!" % [obstacle_index])
		return
	var obstacle = spawned_obstacles[obstacle_index]
	Logger.print(self, "Despawning %s at %s", [obstacle.name, obstacle.position])
	# Only remove it as a child, so the object is still valid in generated_obstacles
	# Defer because it can't be removed during a signal
	call_deferred("remove_child", obstacle)
	var result = spawned_obstacles.erase(obstacle_index)
	assert(result)
