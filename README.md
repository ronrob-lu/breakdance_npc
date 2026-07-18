# breakdance_npc

A [Minetest/Luanti](https://www.luanti.org/) mod by **ronrob-lu** that adds Spanish breakdancer NPCs to your world. They stand idle until a **`ve_radio:radio`**, **`djdeck:mixer`**, **`djdeck:turntable`**, or **`djdeck:loudspeaker`** block appears nearby — then they start dancing!

---

## Features

- **25 randomised Spanish names** (male & female)
- **4 distinct visual styles** (outfits: green/blue, red/orange, purple/gold, cyan/white)
- **13 baked dance animations** across three genres:
  - *Shuffle* — T-Step, Running Man, Heel-Toe, Side Step, Glide
  - *Breakdance* — Six-Step, Windmill, Flare, Baby Freeze, Swipe, Headspin
  - *Streetdance* — The Wave, The Cabbage Patch
- Automatically **detects `ve_radio:radio`, `djdeck:mixer`, `djdeck:turntable`, or `djdeck:loudspeaker`** within 10 nodes
- **Random move selection** — a new move is chosen every second while the radio is active
- NPCs are **invincible** and **static** (decorative)
- Right-click any dancer to see their **name, style & current move**
- Animations baked at **15 fps** into the B3D model

---

## Dependencies

| Dependency | Type | Notes |
|---|---|---|
| Minetest / Luanti | Required | Core engine |
| `default` | Required | For craft recipe items |
| `ve_radio` | **Soft** (optional) | NPCs just stand idle without it |
| `djdeck`   | **Soft** (optional) | NPCs just stand idle without it |

---

## Installation

1. Copy the `breakdance_npc` folder into your Minetest `mods/` directory.
2. Enable the mod in your world settings.
3. Optionally install `ve_radio` or `djdeck` for the dancing to work.

---

## Spawning a Dancer

### Via Craft Recipe

```
  [diamond]
[gold] [stick] [gold]
  [diamond]
```

Right-click a surface with the **Spawn Breakdancer NPC** item.

### Via Chat Command

```
/spawnbd
```

Spawns a dancer at your current position (requires `interact` privilege).

---

## Animation Frame Map

| Frames | Move | Category |
|---|---|---|
| 1 – 30 | Idle (breathing) | — |
| 31 – 60 | T-Step | Shuffle |
| 61 – 90 | Running Man | Shuffle |
| 91 – 120 | Heel-Toe | Shuffle |
| 121 – 150 | Side Step | Shuffle |
| 151 – 180 | Glide | Shuffle |
| 181 – 220 | Six-Step | Breakdance |
| 221 – 270 | Windmill | Breakdance |
| 271 – 320 | Flare | Breakdance |
| 321 – 360 | Baby Freeze | Breakdance |
| 361 – 400 | Swipe | Breakdance |
| 401 – 450 | Headspin | Breakdance |
| 451 – 490 | The Wave | Streetdance |
| 491 – 530 | The Cabbage Patch | Streetdance |

Animation speed: **15 fps** | Total: **530 frames**

---

## Configuration (init.lua constants)

| Constant | Default | Description |
|---|---|---|
| `RADIO_DETECT_RADIUS` | `10` | How far (nodes) the NPC can "hear" the radio |
| `RADIO_CHECK_INTERVAL` | `1.0` | Seconds between radio scans |
| `ANIMATION_FPS` | `15.0` | Playback speed of animations |
| `NAMETAG_COLOR` | `"#FFD700"` | Golden name tag colour |

---

## Files

```
breakdance_npc/
├── init.lua                   ← Main mod logic
├── mod.conf                   ← Metadata (author: ronrob-lu)
├── README.md                  ← This file
├── bake_animations.py         ← Tool used to bake animations into the B3D
├── models/
│   ├── breakdancer.b3d        ← Animated model (530 frames baked)
│   └── breakdancer_original.b3d  ← Backup of the original static model
└── textures/
    ├── breakdancer.png        ← Style 1: green/blue
    ├── breakdancer_2.png      ← Style 2: red/orange hoodie
    ├── breakdancer_3.png      ← Style 3: purple/gold tracksuit
    └── breakdancer_4.png      ← Style 4: cyan/white jacket
```

---

## License

Code: MIT  
Textures: CC BY-SA 4.0  
Author: ronrob-lu
