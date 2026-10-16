------------------
-- Velociraptor --
------------------

local follow = {
	"group:food_meat_raw",
	"group:food_meat",
	"group:bone",
	"bonemeal:bone",
	"animalia:beef_raw",
	"animalia:mutton_raw",
	"animalia:porkchop_raw",
	"animalia:poultry_raw",
}

creatura.register_mob("dinos:velociraptor", {
	-- Stats
	max_health = 35,
	armor_groups = {fleshy = 100},
	damage = 8,
	speed = 7,
	tracking_range = 22,
	despawn_after = 1500,

	-- Physics
	max_fall = 6,
	turn_rate = 7.0,
	stepheight = 1.1,
	bouyancy = 0.25,
	makes_footstep_sound = true,
	hitbox = {
		width = 0.6,
		height = 1.2
	},

	-- Visuals
	mesh = "dinos_velociraptor.b3d",
	textures = {"dinos_velociraptor.png"},
	visual_size = {x = 1.0, y = 1.0},

	-- Animations (from Blender NLA Strip Builder)
	animations = {
		idle = {range = {x = 1, y = 62}, speed = 24, frame_blend = 0.3, loop = true},
		stand = {range = {x = 1, y = 62}, speed = 24, frame_blend = 0.3, loop = true},
		walk = {range = {x = 70, y = 130}, speed = 24, frame_blend = 0.3, loop = true},
		run = {range = {x = 138, y = 153}, speed = 35, frame_blend = 0.3, loop = true},
		attack = {range = {x = 161, y = 183}, speed = 28, frame_blend = 0.3, loop = false},
		melee = {range = {x = 161, y = 183}, speed = 28, frame_blend = 0.3, loop = false},
		death = {range = {x = 191, y = 223}, speed = 24, frame_blend = 0.3, loop = false},
		jump = {range = {x = 231, y = 260}, speed = 24, frame_blend = 0.3, loop = false},
	},

	-- Behavior Parameters
	follow = follow,
	is_herding_mob = true,
	prey = {"dinos:parasaurolophus"},

	-- Drops
	drops = {
		{name = "bonemeal:bone", min = 1, max = 3, chance = 1},
	},

	-- AI Utility Stack (Fast pack predator)
	utility_stack = {
		dinos.mob_ai.basic_wander,
		dinos.mob_ai.swim_seek_land,
		dinos.mob_ai.follow_player,
		dinos.mob_ai.hunt,
	},

	activate_func = dinos.activate_func,
	step_func = dinos.step_func,
	death_func = dinos.death_func,
	on_punch = dinos.on_punch,
	on_rightclick = dinos.on_rightclick,
})

creatura.register_abm_spawn("dinos:velociraptor", {
	chance = 5000,
	interval = 60,
	min_light = 10,
	min_height = 1,
	max_height = 200,
	min_group = 2,
	max_group = 4,
	nodes = {"default:dirt_with_grass", "default:dirt_with_rainforest_litter"},
})
