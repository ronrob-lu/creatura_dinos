# Dinos - Luanti / Minetest Mod

Animated dinosaurs mod for **Luanti / Minetest**, powered by the **Creatura** mob API.

## Features

This mod adds 6 animated prehistoric dinosaurs to Luanti/Minetest:

1. **Apatosaurus** (`dinos:apatosaurus`) - Giant gentle sauropod herbivore with massive health.
2. **Parasaurolophus** (`dinos:parasaurolophus`) - Peaceful duck-billed hadrosaur that lives in herds.
3. **Stegosaurus** (`dinos:stegosaurus`) - Plated herbivore that defends itself with a spiked tail attack when threatened.
4. **T-Rex** (`dinos:trex`) - Massive apex predator carnivore that hunts players and other entities.
5. **Triceratops** (`dinos:triceratops`) - Horned territorial herbivore that charges enemies when provoked.
6. **Velociraptor** (`dinos:velociraptor`) - Fast, agile pack hunter that attacks in groups.

Each dinosaur features fully animated models with smooth transitions:
- `idle`: Standing and ambient movement
- `walk`: Walking motion
- `run`: Fast running motion
- `attack`: Striking / biting animation
- `death`: Defeat animation
- `jump`: Leaping animation

## Dependencies

- **Creatura** (`creatura` mod API)

Optional dependencies:
- `default` (for node group definitions and biome spawning)

## Installation

1. Make sure `creatura` is installed and enabled in your world.
2. Place the `dinos` directory inside your `mods/` directory.
3. Enable `dinos` in your world configuration.

## Spawning

Dinosaurs spawn naturally in grassy, jungle, or forest biomes using Creatura's ABM spawning system.

## Licensing

- **Code**: MIT License (Copyright (c) 2026 ronrob-lu)
- **Models & Media**: CC0 1.0 Universal Public Domain Dedication (LowPoly Models by Quaternius)
