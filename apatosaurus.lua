-- Apatosaurus entity definition using Creatura API

creatura.register_mob("dinos:apatosaurus", {
	-- Visuals
	mesh = "dinos_apatosaurus.b3d",
	textures = {"dinos_apatosaurus.png"},
	visual_size = {x = 1.0, y = 1.0},
	hitbox = {
		width = 2.2,
		height = 3.5
	},

	-- Stats
	max_health = 200,
	damage = 15,
	speed = 3.0,
	tracking_range = 16,
	despawn_after = 1500,
	max_fall = 8,
	turn_rate = 4,

	-- Animations
	animations = {
		idle   = {range = {x = 1, y = 103}, speed = 30, frame_blend = 0.3, loop = true},
		walk   = {range = {x = 113, y = 238}, speed = 30, frame_blend = 0.3, loop = true},
		run    = {range = {x = 248, y = 283}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 293, y = 338}, speed = 30, frame_blend = 0.3, loop = false},
		death  = {range = {x = 348, y = 386}, speed = 30, frame_blend = 0.3, loop = false},
		jump   = {range = {x = 396, y = 440}, speed = 30, frame_blend = 0.3, loop = false},
	},

	drops = {
		{name = "default:bone", min = 3, max = 8, chance = 1},
	},

	utility_stack = {
		{
			utility = "dinos:wander",
			get_score = function(self)
				return 0.1
			end
		},
		{
			utility = "dinos:flee",
			get_score = function(self)
				if self.last_punch_time and (minetest.get_gametime() - self.last_punch_time < 5) then
					local puncher = self.last_puncher
					if creatura.is_valid(puncher) then
						return 0.6, puncher
					end
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

creatura.register_abm_spawn("dinos:apatosaurus", {
	chance = 150,
	interval = 30,
	min_height = -10,
	max_height = 1000,
	min_group = 1,
	max_group = 3,
	nodes = {"default:dirt_with_grass", "default:dry_dirt_with_grass", "group:soil", "group:spreading_dirt_type"}
})
