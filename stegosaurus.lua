-- Stegosaurus entity definition using Creatura API

creatura.register_mob("dinos:stegosaurus", {
	-- Visuals
	mesh = "dinos_stegosaurus.b3d",
	textures = {"dinos_stegosaurus.png"},
	visual_size = {x = 1.0, y = 1.0},
	hitbox = {
		width = 1.5,
		height = 2.2
	},

	-- Stats
	max_health = 80,
	damage = 12,
	speed = 3.5,
	tracking_range = 16,
	despawn_after = 1500,
	max_fall = 6,
	turn_rate = 5,

	-- Animations
	animations = {
		idle   = {range = {x = 1, y = 62}, speed = 30, frame_blend = 0.3, loop = true},
		walk   = {range = {x = 72, y = 142}, speed = 30, frame_blend = 0.3, loop = true},
		run    = {range = {x = 152, y = 171}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 181, y = 226}, speed = 30, frame_blend = 0.3, loop = false},
		death  = {range = {x = 236, y = 274}, speed = 30, frame_blend = 0.3, loop = false},
		jump   = {range = {x = 284, y = 319}, speed = 30, frame_blend = 0.3, loop = false},
	},

	drops = {
		{name = "default:bone", min = 2, max = 5, chance = 1},
	},

	utility_stack = {
		{
			utility = "dinos:wander",
			get_score = function(self)
				return 0.1
			end
		},
		{
			utility = "dinos:counter_attack",
			get_score = function(self)
				if self.last_punch_time and (minetest.get_gametime() - self.last_punch_time < 8) then
					local puncher = self.last_puncher
					if creatura.is_valid(puncher) and creatura.is_alive(puncher) then
						return 0.8, {puncher}
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

creatura.register_abm_spawn("dinos:stegosaurus", {
	chance = 120,
	interval = 30,
	min_height = -10,
	max_height = 1000,
	min_group = 1,
	max_group = 3,
	nodes = {"default:dirt_with_grass", "default:dry_dirt_with_grass", "group:soil", "group:spreading_dirt_type"}
})
