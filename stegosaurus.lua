-- Stegosaurus entity definition using Creatura API

if not creatura.registered_utilities["dinos:counter_attack"] then
	creatura.register_utility("dinos:counter_attack", function(self, target)
		local attack_timer = 0
		local function func(self)
			if not creatura.is_valid(target) or not creatura.is_alive(target) then
				self:halt()
				return true
			end
			local pos = self.object:get_pos()
			local tpos = target:get_pos()
			if not pos or not tpos then
				self:halt()
				return true
			end
			local dist = vector.distance(pos, tpos)
			local reach = (self.width or 1) + 1.5
			if dist <= reach then
				self:halt()
				local dir = vector.direction(pos, tpos)
				self:turn_to(minetest.dir_to_yaw(dir))
				self:animate("attack")
				attack_timer = attack_timer + (self.dtime or 0.1)
				if attack_timer >= 0.5 then
					self:punch_target(target)
					attack_timer = 0
				end
			else
				self:animate("run")
				self:move(tpos, "creatura:obstacle_avoidance", 1.0, "run")
			end
		end
		self:set_utility(func)
	end)
end

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
	chance = 600,
	interval = 60,
	min_height = 0,
	max_height = 100,
	min_group = 1,
	max_group = 3,
	nodes = {"default:dirt_with_grass", "default:dry_dirt_with_grass"}
})
