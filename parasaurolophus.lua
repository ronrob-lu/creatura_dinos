-- Parasaurolophus entity definition using Creatura API

creatura.register_mob("dinos:parasaurolophus", {
	-- Visuals
	mesh = "dinos_parasaurolophus.b3d",
	textures = {"dinos_parasaurolophus.png"},
	visual_size = {x = 1.0, y = 1.0},
	hitbox = {
		width = 1.2,
		height = 2.2
	},

	-- Stats
	max_health = 50,
	damage = 5,
	speed = 4.5,
	tracking_range = 16,
	despawn_after = 1500,
	max_fall = 6,
	turn_rate = 6,

	-- Animations
	animations = {
		idle   = {range = {x = 1, y = 61}, speed = 30, frame_blend = 0.3, loop = true},
		walk   = {range = {x = 71, y = 99}, speed = 30, frame_blend = 0.3, loop = true},
		run    = {range = {x = 109, y = 122}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 132, y = 152}, speed = 30, frame_blend = 0.3, loop = false},
		death  = {range = {x = 162, y = 193}, speed = 30, frame_blend = 0.3, loop = false},
		jump   = {range = {x = 203, y = 235}, speed = 30, frame_blend = 0.3, loop = false},
	},

	drops = {
		{name = "default:bone", min = 1, max = 4, chance = 1},
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
				local player = creatura.get_nearby_player(self)
				if player then
					local dist = vector.distance(self.object:get_pos(), player:get_pos())
					if dist < 6 then
						return 0.5, player
					end
				end
				if self.last_punch_time and (minetest.get_gametime() - self.last_punch_time < 5) then
					local puncher = self.last_puncher
					if creatura.is_valid(puncher) then
						return 0.7, puncher
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

creatura.register_abm_spawn("dinos:parasaurolophus", {
	chance = 100,
	interval = 30,
	min_height = -10,
	max_height = 1000,
	min_group = 2,
	max_group = 5,
	nodes = {"default:dirt_with_grass", "default:dry_dirt_with_grass", "group:soil", "group:spreading_dirt_type"}
})
