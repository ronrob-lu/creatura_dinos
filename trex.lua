-----------
-- T-Rex --
-----------

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

creatura.register_mob("dinos:trex", {
	-- Stats
	max_health = 120,
	armor_groups = {fleshy = 75},
	damage = 18,
	speed = 5.5,
	tracking_range = 28,
	despawn_after = 1500,

	-- Physics
	max_fall = 5,
	turn_rate = 4.5,
	stepheight = 1.1,
	bouyancy = 0.25,
	makes_footstep_sound = true,
	hitbox = {
		width = 1.5,
		height = 3.8
	},

	-- Visuals
	mesh = "dinos_trex.b3d",
	textures = {"dinos_trex.png"},
	visual_size = {x = 1.0, y = 1.0},

	-- Animations (from Blender NLA Strip Builder)
	animations = {
		idle = {range = {x = 1, y = 62}, speed = 24, frame_blend = 0.3, loop = true},
		stand = {range = {x = 1, y = 62}, speed = 24, frame_blend = 0.3, loop = true},
		walk = {range = {x = 70, y = 105}, speed = 24, frame_blend = 0.3, loop = true},
		run = {range = {x = 113, y = 137}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 145, y = 175}, speed = 24, frame_blend = 0.3, loop = false},
		melee = {range = {x = 145, y = 175}, speed = 24, frame_blend = 0.3, loop = false},
		death = {range = {x = 183, y = 222}, speed = 24, frame_blend = 0.3, loop = false},
		jump = {range = {x = 230, y = 267}, speed = 24, frame_blend = 0.3, loop = false},
	},

	-- Behavior Parameters
	follow = follow,
	prey = {"dinos:parasaurolophus", "dinos:triceratops", "dinos:stegosaurus"},

	-- Drops
	drops = {
		{name = "bonemeal:bone", min = 4, max = 10, chance = 1},
	},

	-- AI Utility Stack (Apex Predator)
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

creatura.register_abm_spawn("dinos:trex", {
	chance = 10000,
	interval = 60,
	min_light = 10,
	min_height = 1,
	max_height = 200,
	min_group = 1,
	max_group = 1,
	nodes = {"default:dirt_with_grass", "default:dirt_with_rainforest_litter"},
})
