-- Tyrannosaurus Rex entity definition using Creatura API

if not creatura.registered_utilities["dinos:hunt"] then
	creatura.register_utility("dinos:hunt", function(self, target)
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
			local reach = (self.width or 1) + 1.8
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

creatura.register_mob("dinos:trex", {
	-- Visuals
	mesh = "dinos_trex.b3d",
	textures = {"dinos_trex.png"},
	visual_size = {x = 1.0, y = 1.0},
	hitbox = {
		width = 2.0,
		height = 3.8
	},

	-- Stats
	max_health = 150,
	damage = 25,
	speed = 5.5,
	tracking_range = 24,
	despawn_after = 1500,
	max_fall = 8,
	turn_rate = 5,

	-- Animations
	animations = {
		idle   = {range = {x = 1, y = 61}, speed = 30, frame_blend = 0.3, loop = true},
		walk   = {range = {x = 71, y = 104}, speed = 30, frame_blend = 0.3, loop = true},
		run    = {range = {x = 114, y = 136}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 146, y = 174}, speed = 30, frame_blend = 0.3, loop = false},
		death  = {range = {x = 184, y = 222}, speed = 30, frame_blend = 0.3, loop = false},
		jump   = {range = {x = 232, y = 267}, speed = 30, frame_blend = 0.3, loop = false},
	},

	drops = {
		{name = "default:bone", min = 5, max = 12, chance = 1},
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
					return 0.8, {player}
				end
				local nearby_dino = creatura.get_nearby_object(self, {
					"dinos:parasaurolophus",
					"dinos:stegosaurus",
					"dinos:triceratops",
					"dinos:apatosaurus"
				})
				if nearby_dino and creatura.is_alive(nearby_dino) then
					return 0.7, {nearby_dino}
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

creatura.register_abm_spawn("dinos:trex", {
	chance = 1200,
	interval = 60,
	min_height = 0,
	max_height = 100,
	min_group = 1,
	max_group = 1,
	nodes = {"default:dirt_with_grass", "default:dry_dirt_with_grass"}
})
