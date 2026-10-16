-- Apatosaurus entity definition using Creatura API

if not creatura.registered_utilities["dinos:wander"] then
	creatura.register_utility("dinos:wander", function(self)
		local timer = math.random(4, 10)
		local goal
		local function func(self)
			timer = timer - (self.dtime or 0.1)
			if timer <= 0 then
				self:halt()
				return true
			end
			if not goal then
				local pos = self.object:get_pos()
				if pos then
					local angle = math.random() * math.pi * 2
					local dist = math.random(6, 14)
					goal = {
						x = pos.x + math.cos(angle) * dist,
						y = pos.y,
						z = pos.z + math.sin(angle) * dist
					}
				end
			end
			if goal then
				self:animate("walk")
				if self:move(goal, "creatura:obstacle_avoidance", 0.5, "walk") then
					self:halt()
					return true
				end
			end
		end
		self:set_utility(func)
	end)
end

if not creatura.registered_utilities["dinos:flee"] then
	creatura.register_utility("dinos:flee", function(self, threat)
		local timer = math.random(5, 8)
		local function func(self)
			timer = timer - (self.dtime or 0.1)
			if timer <= 0 or not creatura.is_valid(threat) then
				self:halt()
				return true
			end
			local pos = self.object:get_pos()
			local tpos = threat:get_pos()
			if not pos or not tpos then
				self:halt()
				return true
			end
			local dir = vector.direction(tpos, pos)
			local goal = {x = pos.x + dir.x * 15, y = pos.y, z = pos.z + dir.z * 15}
			self:animate("run")
			if self:move(goal, "creatura:obstacle_avoidance", 1.2, "run") then
				self:halt()
				return true
			end
		end
		self:set_utility(func)
	end)
end

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
						return 0.6, {puncher}
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
	chance = 800,
	interval = 60,
	min_height = 0,
	max_height = 100,
	min_group = 1,
	max_group = 3,
	nodes = {"default:dirt_with_grass", "default:dry_dirt_with_grass"}
})
