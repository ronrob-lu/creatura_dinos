---------------------
-- Parasaurolophus --
---------------------

local follow = {
	"default:leaves",
	"default:jungleleaves",
	"default:fern_1",
	"default:fern_2",
	"default:fern_3",
	"default:apple",
	"farming:wheat",
	"group:flora",
	"group:leaves",
}

creatura.register_mob("dinos:parasaurolophus", {
	-- Stats
	max_health = 40,
	armor_groups = {fleshy = 100},
	damage = 4,
	speed = 5,
	tracking_range = 16,
	despawn_after = 1500,

	-- Physics
	max_fall = 4,
	turn_rate = 6.0,
	stepheight = 1.1,
	bouyancy = 0.25,
	makes_footstep_sound = true,
	hitbox = {
		width = 0.9,
		height = 2.2
	},

	-- Visuals
	mesh = "dinos_parasaurolophus.b3d",
	textures = {"dinos_parasaurolophus.png"},
	visual_size = {x = 1.0, y = 1.0},

	-- Animations (from Blender NLA Strip Builder)
	animations = {
		idle = {range = {x = 1, y = 62}, speed = 24, frame_blend = 0.3, loop = true},
		stand = {range = {x = 1, y = 62}, speed = 24, frame_blend = 0.3, loop = true},
		walk = {range = {x = 70, y = 100}, speed = 24, frame_blend = 0.3, loop = true},
		run = {range = {x = 108, y = 123}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 131, y = 153}, speed = 24, frame_blend = 0.3, loop = false},
		melee = {range = {x = 131, y = 153}, speed = 24, frame_blend = 0.3, loop = false},
		death = {range = {x = 161, y = 193}, speed = 24, frame_blend = 0.3, loop = false},
		jump = {range = {x = 201, y = 235}, speed = 24, frame_blend = 0.3, loop = false},
	},

	-- Behavior Parameters
	follow = follow,
	is_herding_mob = true,
	is_grazing_mob = true,
	is_skittish_mob = true,
	predators = {"dinos:trex", "dinos:velociraptor"},

	-- Drops
	drops = {
		{name = "bonemeal:bone", min = 1, max = 3, chance = 1},
	},

	-- AI Utility Stack (Peaceful herbivore, flees when attacked or near predators)
	utility_stack = {
		dinos.mob_ai.basic_wander,
		dinos.mob_ai.swim_seek_land,
		dinos.mob_ai.follow_player,
		dinos.mob_ai.flee,
	},

	activate_func = dinos.activate_func,
	step_func = dinos.step_func,
	death_func = dinos.death_func,
	on_punch = dinos.on_punch,
	on_rightclick = dinos.on_rightclick,
})

creatura.register_abm_spawn("dinos:parasaurolophus", {
	chance = 5000,
	interval = 60,
	min_light = 10,
	min_height = 1,
	max_height = 200,
	min_group = 2,
	max_group = 4,
	nodes = {"default:dirt_with_grass", "default:dirt_with_rainforest_litter"},
})
