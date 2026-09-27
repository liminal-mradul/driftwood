extends CharacterBody2D

# ============================================================
# STORY
# A shipwrecked castaway on a nameless island. There's no rescue
# coming — the only way home is a raft, and the only way to build
# one is thirty logs of wood, gathered before hunger finishes the job
# the sea started.
# ============================================================

# Movement speed (pixels per second)
@export var speed: float = 150.0

# Reference to the AnimatedSprite2D node
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

# Reference to tree and food layers (adjust path based on your scene structure)
@onready var tree_layer: TileMapLayer = null
@onready var food_layer: TileMapLayer = null

# Track current direction for animations
var last_direction: Vector2 = Vector2.DOWN
var boat_message_label: Label = null

# Inventory
var inventory: Dictionary = {}
var inventory_ui: Control = null

# Player stats
var max_health: float = 100.0
var current_health: float = 100.0
var max_food: float = 100.0
var current_food: float = 100.0

# UI references
var health_bar: ProgressBar = null
var food_bar: ProgressBar = null

# Wood counter
var trees_cut: int = 0
var trees_needed_for_boat: int = 40
var cold_snap_started: bool = false
var has_boat: bool = false
var wood_counter_label: Label = null

# Day / survival tracking
var day_label: Label = null
var survival_time: float = 0.0

# Story beats
var intro_ui: CanvasLayer = null
var intro_dismissed: bool = false
var story_label: Label = null
var story_message_timer: float = 0.0
var told_first_wood: bool = false
var told_halfway: bool = false
var is_dead_or_escaped: bool = false

func _ready():
	setup_camera()
	setup_boat_message()
	setup_story_toast()
	setup_tree_layer()
	setup_food_layer()
	setup_inventory_ui()
	setup_stats_ui()
	setup_wood_counter()
	setup_day_counter()
	setup_intro()

func setup_camera():
	# Create camera if it doesn't exist
	if not has_node("Camera2D"):
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	
	# Make this camera active
	camera.enabled = true
	
	# Zoom in (higher values = more zoomed in)
	camera.zoom = Vector2(2.0, 2.0)  # Adjust this value (try 1.5, 2.0, 2.5, 3.0)
	
	# Smooth camera movement
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	print("Camera setup complete with zoom: ", camera.zoom)

func setup_boat_message():
	# Create the message label
	boat_message_label = Label.new()
	boat_message_label.name = "BoatMessage"
	boat_message_label.text = "You need a raft!"
	boat_message_label.position = Vector2(-50, -40)
	boat_message_label.add_theme_color_override("font_color", Color.WHITE)
	boat_message_label.add_theme_font_size_override("font_size", 14)
	
	# Add background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)
	style_box.set_corner_radius_all(5)
	style_box.content_margin_left = 8
	style_box.content_margin_right = 8
	style_box.content_margin_top = 4
	style_box.content_margin_bottom = 4
	boat_message_label.add_theme_stylebox_override("normal", style_box)
	
	add_child(boat_message_label)
	boat_message_label.visible = false

func setup_story_toast():
	# A small narrator line that fades in whenever something story-worthy
	# happens (first wood cut, raft finished, etc). Separate from the
	# boat-shore prompt so the two never fight for the same line.
	var toast_canvas = CanvasLayer.new()
	toast_canvas.name = "StoryCanvas"
	toast_canvas.layer = 5
	add_child(toast_canvas)

	story_label = Label.new()
	story_label.name = "StoryToast"
	story_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	story_label.position = Vector2(-260, 40)
	story_label.custom_minimum_size = Vector2(520, 0)
	story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	story_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8, 1))
	story_label.add_theme_font_size_override("font_size", 16)

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.6)
	style_box.set_corner_radius_all(6)
	style_box.content_margin_left = 12
	style_box.content_margin_right = 12
	style_box.content_margin_top = 6
	style_box.content_margin_bottom = 6
	story_label.add_theme_stylebox_override("normal", style_box)

	toast_canvas.add_child(story_label)
	story_label.visible = false

func show_story_message(text: String, duration: float = 4.0):
	story_label.text = text
	story_label.visible = true
	story_message_timer = duration

func setup_intro():
	intro_ui = CanvasLayer.new()
	intro_ui.name = "IntroCanvas"
	intro_ui.layer = 10
	add_child(intro_ui)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.85)
	panel.add_theme_stylebox_override("panel", panel_style)
	intro_ui.add_child(panel)

	var text_label = Label.new()
	text_label.set_anchors_preset(Control.PRESET_CENTER)
	text_label.position = Vector2(-260, -110)
	text_label.custom_minimum_size = Vector2(520, 0)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.text = "The storm took the ship. It didn't take you.\n\nYou wake on an empty shore with nothing but wet clothes and a long walk ahead. No rescue is coming — the only way home is a raft, and a raft needs wood.\n\nGather %d logs, keep yourself fed, and reach the water before your strength runs out. It gets harder the longer you stay — every log costs more energy than the last, and the nights only get colder." % trees_needed_for_boat
	intro_ui.add_child(text_label)

	var prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-150, -60)
	prompt_label.custom_minimum_size = Vector2(300, 0)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.text = "Press SPACE to wake up"
	intro_ui.add_child(prompt_label)

func setup_tree_layer():
	# Try to find the tree layer - adjust these paths based on your scene
	var possible_paths = [
		"../Trees",
		"../tree_layer", 
		"../../Trees",
		"../grassland/Trees",
		"../Node/Trees"
	]
	
	for path in possible_paths:
		if has_node(path):
			tree_layer = get_node(path)
			print("Tree layer found at: ", path)
			break
	
	if tree_layer == null:
		print("Warning: Tree layer not found. Tree cutting disabled.")

func setup_food_layer():
	# Try to find the food layer - adjust these paths based on your scene
	var possible_paths = [
		"../Food",
		"../food_layer",
		"../../Food",
		"../grassland/Food",
		"../Node/Food"
	]
	
	for path in possible_paths:
		if has_node(path):
			food_layer = get_node(path)
			print("Food layer found at: ", path)
			break
	
	if food_layer == null:
		print("Warning: Food layer not found. Food mechanics disabled.")

func setup_inventory_ui():
	# Create a CanvasLayer so UI stays on screen regardless of camera
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "InventoryCanvas"
	add_child(canvas_layer)
	
	# Create inventory UI panel
	inventory_ui = Control.new()
	inventory_ui.name = "InventoryUI"
	canvas_layer.add_child(inventory_ui)
	
	# Make it fill the screen to position correctly
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Background panel positioned at top-right
	var panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-220, 10)
	panel.size = Vector2(200, 300)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	inventory_ui.add_child(panel)
	
	# Title label
	var title = Label.new()
	title.text = "Inventory"
	title.position = Vector2(60, 15)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))  # Gold color
	panel.add_child(title)
	
	# Inventory items container
	var items_container = VBoxContainer.new()
	items_container.name = "ItemsContainer"
	items_container.position = Vector2(15, 50)
	items_container.size = Vector2(170, 240)
	items_container.add_theme_constant_override("separation", 5)
	panel.add_child(items_container)
	
	# Start with inventory hidden
	inventory_ui.visible = false
	
	print("Inventory UI setup complete - Press TAB to toggle")

func setup_stats_ui():
	# Create a CanvasLayer for stats UI
	var stats_canvas = CanvasLayer.new()
	stats_canvas.name = "StatsCanvas"
	add_child(stats_canvas)
	
	# Create container for stats
	var stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.position = Vector2(10, 10)
	stats_container.add_theme_constant_override("separation", 5)
	stats_canvas.add_child(stats_container)
	
	# Health Bar Label
	var health_label = Label.new()
	health_label.text = "Health"
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_font_size_override("font_size", 14)
	stats_container.add_child(health_label)
	
	# Health Bar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(200, 20)
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	
	# Style health bar
	var health_style = StyleBoxFlat.new()
	health_style.bg_color = Color(0.8, 0.2, 0.2, 1)  # Red
	health_bar.add_theme_stylebox_override("fill", health_style)
	
	var health_bg = StyleBoxFlat.new()
	health_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray
	health_bar.add_theme_stylebox_override("background", health_bg)
	
	stats_container.add_child(health_bar)
	
	# Food Bar Label
	var food_label = Label.new()
	food_label.text = "Food"
	food_label.add_theme_color_override("font_color", Color.WHITE)
	food_label.add_theme_font_size_override("font_size", 14)
	stats_container.add_child(food_label)
	
	# Food Bar
	food_bar = ProgressBar.new()
	food_bar.size = Vector2(200, 20)
	food_bar.min_value = 0
	food_bar.max_value = max_food
	food_bar.value = current_food
	food_bar.show_percentage = false
	
	# Style food bar
	var food_style = StyleBoxFlat.new()
	food_style.bg_color = Color(0.9, 0.6, 0.2, 1)  # Orange
	food_bar.add_theme_stylebox_override("fill", food_style)
	
	var food_bg = StyleBoxFlat.new()
	food_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray
	food_bar.add_theme_stylebox_override("background", food_bg)
	
	stats_container.add_child(food_bar)
	
	print("Stats UI setup complete")

func setup_wood_counter():
	# Create a CanvasLayer for wood counter
	var wood_canvas = CanvasLayer.new()
	wood_canvas.name = "WoodCanvas"
	add_child(wood_canvas)
	
	# Create wood counter label
	wood_counter_label = Label.new()
	wood_counter_label.name = "WoodCounter"
	wood_counter_label.position = Vector2(10, 100)
	wood_counter_label.add_theme_font_size_override("font_size", 18)
	
	# Add background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style_box.set_corner_radius_all(5)
	style_box.content_margin_left = 10
	style_box.content_margin_right = 10
	style_box.content_margin_top = 5
	style_box.content_margin_bottom = 5
	wood_counter_label.add_theme_stylebox_override("normal", style_box)
	
	wood_canvas.add_child(wood_counter_label)
	update_wood_counter()

func setup_day_counter():
	var day_canvas = CanvasLayer.new()
	day_canvas.name = "DayCanvas"
	add_child(day_canvas)

	day_label = Label.new()
	day_label.name = "DayCounter"
	day_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	day_label.position = Vector2(-140, 100)
	day_label.add_theme_font_size_override("font_size", 18)
	day_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1))

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style_box.set_corner_radius_all(5)
	style_box.content_margin_left = 10
	style_box.content_margin_right = 10
	style_box.content_margin_top = 5
	style_box.content_margin_bottom = 5
	day_label.add_theme_stylebox_override("normal", style_box)

	day_canvas.add_child(day_label)
	update_day_counter()

func update_day_counter():
	if day_label:
		day_label.text = "Day %d" % GameState.get_day()

func update_wood_counter():
	if wood_counter_label:
		wood_counter_label.text = "Wood: %d/%d" % [trees_cut, trees_needed_for_boat]
		
		# Change color based on progress
		if has_boat:
			wood_counter_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1))  # Green
		elif trees_cut >= trees_needed_for_boat:
			wood_counter_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1))  # Gold
			if not has_boat:
				craft_boat()
		else:
			wood_counter_label.add_theme_color_override("font_color", Color.WHITE)

func craft_boat():
	has_boat = true
	GameState.has_boat = true
	add_item("Raft", 1)
	update_wood_counter()
	show_story_message("The raft is finished. Get to the water while you still have the strength to paddle.", 5.0)

func _physics_process(delta):
	# The intro screen blocks play until the castaway "wakes up".
	if not intro_dismissed:
		if Input.is_action_just_pressed("ui_accept"):
			intro_dismissed = true
			intro_ui.visible = false
		else:
			return

	if is_dead_or_escaped:
		return

	# Get input direction
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	# Normalize diagonal movement
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		last_direction = input_dir
	
	# Set velocity
	velocity = input_dir * speed
	
	# Use move_and_slide - handles collisions automatically
	move_and_slide()
	
	# Check if we're colliding with water
	var is_touching_water = false
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and "water" in collider.name.to_lower():
			is_touching_water = true
			break
	
	# Update boat message based on boat status
	if is_touching_water:
		if has_boat:
			boat_message_label.text = "Press SPACE to set out for home"
			boat_message_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1))
			boat_message_label.visible = true
			
			# Win condition - player can escape
			if Input.is_action_just_pressed("ui_accept"):
				win_game()
		else:
			boat_message_label.text = "You need a raft! (%d/%d wood)" % [trees_cut, trees_needed_for_boat]
			boat_message_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))
			boat_message_label.visible = true
	else:
		boat_message_label.visible = false
	
	# Update animation
	update_animation(input_dir)
	
	# Try to cut tree or gather food
	try_cut_tree()
	
	# Toggle inventory with TAB key
	if Input.is_action_just_pressed("ui_cancel"):  # ESC key
		toggle_inventory()
	# Or use TAB if you add it to input map as "toggle_inventory"
	if Input.is_key_pressed(KEY_TAB) and Input.is_action_just_pressed("ui_focus_next"):
		toggle_inventory()
	
	# Handle interdependent health/food drain
	handle_stat_drain(delta)

	# Track survival time for the day counter and end-screen stats
	survival_time += delta
	GameState.survival_time = survival_time
	update_day_counter()

	# Fade the narrator toast after its time is up
	if story_label.visible:
		story_message_timer -= delta
		if story_message_timer <= 0:
			story_label.visible = false

func try_cut_tree():
	if tree_layer == null:
		return
	
	# Check if player pressed action button (Space)
	if Input.is_action_just_pressed("ui_accept"):
		# Play attack animation based on direction
		play_attack_animation()
		
		# Search for trees in a smaller radius around player
		var player_tile_pos = tree_layer.local_to_map(global_position)
		
		# Check tiles in a 3x3 area around player
		var found_tree = false
		var found_food = false
		
		for x_offset in range(-1, 2):
			for y_offset in range(-1, 2):
				var check_tile_pos = player_tile_pos + Vector2i(x_offset, y_offset)
				
				# Check for tree tile
				var tree_tile_data = tree_layer.get_cell_tile_data(check_tile_pos)
				if tree_tile_data != null:
					found_tree = true
				
				# Check for food tile
				if food_layer != null:
					var food_tile_data = food_layer.get_cell_tile_data(check_tile_pos)
					if food_tile_data != null:
						found_food = true
		
		# Now decide what happens based on what was found.
		# Wood always comes first: even when a food tile sits right next
		# to a tree, chopping doesn't also feed you — foraging is its
		# own trip, so you can't safely grind wood forever.
		if found_tree:
			cut_tree_at_position(player_tile_pos)
			var fatigue_cost = get_wood_fatigue_cost()
			decrease_food(fatigue_cost)
			print("Cut tree - lost ", fatigue_cost, " food from the work")
		elif found_food:
			destroy_food_at_position(player_tile_pos)
			increase_food(20)  # Gain 20 food
			GameState.food_gathered += 1
			print("Gathered food - hunger decreased!")
		else:
			# Nothing to interact with
			decrease_food(2)  # Still lose a bit of energy from swinging

func get_wood_fatigue_cost() -> float:
	# Each log costs a bit more than the last - the work wears you down
	# faster the more of the island you've already cleared, so the final
	# stretch toward the raft is the most dangerous part of the run.
	return 5.0 + floor(trees_cut / 8.0) * 2.0

func cut_tree_at_position(player_tile_pos: Vector2i):
	if tree_layer == null:
		return
	
	# Check tiles in a 3x3 area
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			var check_tile_pos = player_tile_pos + Vector2i(x_offset, y_offset)
			var tile_data = tree_layer.get_cell_tile_data(check_tile_pos)
			
			if tile_data != null:
				# Remove tree tiles
				tree_layer.erase_cell(check_tile_pos)
				tree_layer.erase_cell(check_tile_pos + Vector2i(0, -1))
				tree_layer.erase_cell(check_tile_pos + Vector2i(0, 1))
				tree_layer.erase_cell(check_tile_pos + Vector2i(-1, 0))
				tree_layer.erase_cell(check_tile_pos + Vector2i(1, 0))
				tree_layer.erase_cell(check_tile_pos + Vector2i(-1, -1))
				tree_layer.erase_cell(check_tile_pos + Vector2i(1, -1))
				tree_layer.erase_cell(check_tile_pos + Vector2i(-1, 1))
				tree_layer.erase_cell(check_tile_pos + Vector2i(1, 1))
				
				# Increment tree counter
				trees_cut += 1
				GameState.wood_collected = trees_cut
				add_item("Wood", 1)
				update_wood_counter()
				announce_wood_milestones()
				
				print("Tree cut! Total trees: ", trees_cut)
				return

func announce_wood_milestones():
	if not told_first_wood and trees_cut >= 1:
		told_first_wood = true
		show_story_message("Wood. Not much, but it's a start toward getting off this island.")
	elif not told_halfway and trees_cut >= int(trees_needed_for_boat / 2.0):
		told_halfway = true
		show_story_message("Halfway to enough wood for a raft. Keep going.")

func destroy_food_at_position(player_tile_pos: Vector2i):
	if food_layer == null:
		return
	
	# Check tiles in a 3x3 area
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			var check_tile_pos = player_tile_pos + Vector2i(x_offset, y_offset)
			var tile_data = food_layer.get_cell_tile_data(check_tile_pos)
			
			if tile_data != null:
				# Remove food tile
				food_layer.erase_cell(check_tile_pos)

func play_attack_animation():
	# Play the single attack animation
	if anim_sprite.sprite_frames.has_animation("DOWN_ATTACK"):
		anim_sprite.play("DOWN_ATTACK")
	elif anim_sprite.sprite_frames.has_animation("ATTACK"):
		anim_sprite.play("ATTACK")
	else:
		print("No attack animation found!")

func toggle_inventory():
	if inventory_ui:
		inventory_ui.visible = !inventory_ui.visible
		print("Inventory toggled: ", inventory_ui.visible)

func add_item(item_name: String, quantity: int = 1):
	# Add to inventory dictionary
	if inventory.has(item_name):
		inventory[item_name] += quantity
	else:
		inventory[item_name] = quantity
	
	# Update UI
	update_inventory_display()
	print("Added ", quantity, "x ", item_name, " to inventory. Total: ", inventory[item_name])

func update_inventory_display():
	if not inventory_ui:
		return
	
	var panel = inventory_ui.get_node("Panel")
	var container = panel.get_node("ItemsContainer")
	
	# Clear existing items
	for child in container.get_children():
		child.queue_free()
	
	# Add all inventory items
	for item_name in inventory.keys():
		var item_row = HBoxContainer.new()
		item_row.add_theme_constant_override("separation", 10)
		
		# Item name
		var name_label = Label.new()
		name_label.text = str(item_name)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.custom_minimum_size = Vector2(100, 0)
		item_row.add_child(name_label)
		
		# Item quantity
		var qty_label = Label.new()
		qty_label.text = "x" + str(inventory[item_name])
		qty_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1))
		qty_label.add_theme_font_size_override("font_size", 16)
		item_row.add_child(qty_label)
		
		container.add_child(item_row)

func decrease_health(amount: float):
	current_health -= amount
	if current_health < 0:
		current_health = 0
	
	if health_bar:
		health_bar.value = current_health
	
	print("Health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func die():
	if is_dead_or_escaped:
		return
	is_dead_or_escaped = true

	# Record why the run ended so the death screen can say something true.
	GameState.death_cause = "starvation" if current_food <= 0 else "exposure"
	GameState.wood_collected = trees_cut
	GameState.survival_time = survival_time

	print("Player died! Cause: ", GameState.death_cause)
	# Change to loose scene
	get_tree().change_scene_to_file("res://scenes/loose.tscn")

func win_game():
	if is_dead_or_escaped:
		return
	is_dead_or_escaped = true

	GameState.wood_collected = trees_cut
	GameState.survival_time = survival_time
	GameState.has_boat = true

	print("YOU WIN! Escaped the island!")
	# Change to win scene
	get_tree().change_scene_to_file("res://scenes/win.tscn")

func decrease_food(amount: float):
	current_food -= amount
	if current_food < 0:
		current_food = 0
	
	if food_bar:
		food_bar.value = current_food
	
	print("Food: ", current_food, "/", max_food)

func increase_health(amount: float):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	
	if health_bar:
		health_bar.value = current_health

func increase_food(amount: float):
	current_food += amount
	if current_food > max_food:
		current_food = max_food
	
	if food_bar:
		food_bar.value = current_food

func handle_stat_drain(delta):
	# Passive food drain over time (hunger)
	var food_drain_rate = 1.4  # Food lost per second

	# After day 4 the nights turn cold - staying safe on the beach
	# forever is no longer an option, wood or no wood.
	if GameState.get_day() >= 4:
		food_drain_rate += 0.6
		if not cold_snap_started:
			cold_snap_started = true
			show_story_message("The nights are turning cold. You can't just wait this out anymore.", 5.0)

	# If health is low, hunger increases faster
	if current_health < 30:
		food_drain_rate *= 3.0  # 3x faster when health is critical
	elif current_health < 50:
		food_drain_rate *= 2.0  # 2x faster when health is low
	
	current_food -= food_drain_rate * delta
	if current_food < 0:
		current_food = 0
	
	if food_bar:
		food_bar.value = current_food
	
	# If food is low/zero, health drains
	if current_food <= 0:
		# Starving - rapid health loss
		decrease_health(7 * delta)  # Lose 7 health per second when starving
	elif current_food < 20:
		# Very hungry - slow health loss
		decrease_health(3 * delta)  # Lose 3 health per second when very hungry
	elif current_food < 40:
		# Hungry - very slow health loss
		decrease_health(1 * delta)  # Lose 1 health per second when hungry
	
	# Update bars
	if health_bar:
		health_bar.value = current_health
	if food_bar:
		food_bar.value = current_food

func update_animation(direction: Vector2):
	if direction.length() > 0:
		# Moving
		if abs(direction.x) > abs(direction.y):
			# Horizontal movement
			if direction.x > 0:
				if anim_sprite.sprite_frames.has_animation("SIDE_WALK"):
					anim_sprite.play("SIDE_WALK")
					anim_sprite.flip_h = true
				elif anim_sprite.sprite_frames.has_animation("DOWN_WALK"):
					anim_sprite.play("DOWN_WALK")
			else:
				if anim_sprite.sprite_frames.has_animation("SIDE_WALK"):
					anim_sprite.play("SIDE_WALK")
					anim_sprite.flip_h = false
				elif anim_sprite.sprite_frames.has_animation("DOWN_WALK"):
					anim_sprite.play("DOWN_WALK")
		else:
			# Vertical movement
			if direction.y > 0:
				if anim_sprite.sprite_frames.has_animation("DOWN_WALK"):
					anim_sprite.play("DOWN_WALK")
			else:
				if anim_sprite.sprite_frames.has_animation("UP_WALK"):
					anim_sprite.play("UP_WALK")
	else:
		# Idle
		if abs(last_direction.x) > abs(last_direction.y):
			# Horizontal idle
			if last_direction.x > 0:
				if anim_sprite.sprite_frames.has_animation("SIDE_IDLE"):
					anim_sprite.play("SIDE_IDLE")
					anim_sprite.flip_h = true
				elif anim_sprite.sprite_frames.has_animation("DOWN_IDLE"):
					anim_sprite.play("DOWN_IDLE")
			else:
				if anim_sprite.sprite_frames.has_animation("SIDE_IDLE"):
					anim_sprite.play("SIDE_IDLE")
					anim_sprite.flip_h = false
				elif anim_sprite.sprite_frames.has_animation("DOWN_IDLE"):
					anim_sprite.play("DOWN_IDLE")
		else:
			# Vertical idle
			if last_direction.y > 0:
				if anim_sprite.sprite_frames.has_animation("DOWN_IDLE"):
					anim_sprite.play("DOWN_IDLE")
			else:
				if anim_sprite.sprite_frames.has_animation("UP_IDLE"):
					anim_sprite.play("UP_IDLE")
