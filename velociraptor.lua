-- Velociraptor entity definition using Creatura API

creatura.register_mob("dinos:velociraptor", {
	-- Visuals
	mesh = "dinos_velociraptor.b3d",
	textures = {"dinos_velociraptor.png"},
	visual_size = {x = 1.0, y = 1.0},
	hitbox = {
		width = 0.7,
		height = 1.2
	},

	-- Stats
	max_health = 30,
	damage = 8,
	speed = 6.5,
	tracking_range = 20,
	despawn_after = 1500,
	max_fall = 5,
	turn_rate = 8,

	-- Animations
	animations = {
		idle   = {range = {x = 1, y = 61}, speed = 30, frame_blend = 0.3, loop = true},
		walk   = {range = {x = 71, y = 129}, speed = 30, frame_blend = 0.3, loop = true},
		run    = {range = {x = 139, y = 152}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 162, y = 182}, speed = 30, frame_blend = 0.3, loop = false},
		death  = {range = {x = 192, y = 223}, speed = 30, frame_blend = 0.3, loop = false},
		jump   = {range = {x = 233, y = 260}, speed = 30, frame_blend = 0.3, loop = false},
	},

	drops = {
		{name = "default:bone", min = 1, max = 3, chance = 1},
	},

	utility_stack = {
		{
			utility = "dinos:wander",
			get_score = function(self)
				return 0.1
			end
		},
		{
			utility = "dinos:hunt",
			get_score = function(self)
				local player = creatura.get_nearby_player(self)
				if player and creatura.is_alive(player) then
					return 0.8, player
				end
				local nearby_dino = creatura.get_nearby_object(self, {
					"dinos:parasaurolophus"
				})
				if nearby_dino and creatura.is_alive(nearby_dino) then
					return 0.7, nearby_dino
				end
				return 0
			end
		}
	},

	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction)
		self.last_puncher = puncher
		self.last_punch_time = minetest.get_gametime()
		creatura.basic_punch_func(self, puncher, time_from_last_punch, tool_capabilities, direction)
	end
})

creatura.register_abm_spawn("dinos:velociraptor", {
	chance = 100,
	interval = 30,
	min_height = -10,
	max_height = 1000,
	min_group = 2,
	max_group = 6,
	nodes = {"default:dirt_with_grass", "default:dry_dirt_with_grass", "group:soil", "group:spreading_dirt_type"}
})
