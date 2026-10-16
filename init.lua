-- Dinos Mod for Luanti / Minetest using Creatura API
-- License: Code MIT (ronrob-lu 2026 mit), Media CC0 (Quaternius)

local modpath = minetest.get_modpath("dinos")

minetest.log("action", "[dinos] Loading animated dinosaur mod...")

dofile(modpath .. "/apatosaurus.lua")
dofile(modpath .. "/parasaurolophus.lua")
dofile(modpath .. "/stegosaurus.lua")
dofile(modpath .. "/trex.lua")
dofile(modpath .. "/triceratops.lua")
dofile(modpath .. "/velociraptor.lua")

minetest.log("action", "[dinos] Dinosaurs loaded successfully!")
