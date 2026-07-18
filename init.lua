-- =============================================================================
-- breakdance_npc / init.lua
-- Author: ronrob-lu
-- =============================================================================
-- Spanish breakdancer NPCs that idle until a ve_radio:radio, djdeck:mixer,
-- djdeck:turntable, or djdeck:loudspeaker block appears nearby, then break
-- into randomised dance moves.
--
-- B3D animation frame layout (15 fps):
--   1  –  30 : Idle      (breathing)
--  31  –  60 : T-Step         [shuffle]
--  61  –  90 : Running Man    [shuffle]
--  91  – 120 : Heel-Toe       [shuffle]
-- 121  – 150 : Side Step      [shuffle]
-- 151  – 180 : Glide          [shuffle]
-- 181  – 220 : Six-Step       [breakdance]
-- 221  – 270 : Windmill       [breakdance]
-- 271  – 320 : Flare          [breakdance]
-- 321  – 360 : Baby Freeze    [breakdance]
-- 361  – 400 : Swipe          [breakdance]
-- 401  – 450 : Headspin       [breakdance]
-- 451  – 490 : The Wave       [streetdance]
-- 491  – 530 : Cabbage Patch  [streetdance]
-- =============================================================================

-- ──────────────────────────────────────────────────────────────────────────────
-- CONFIGURATION
-- ──────────────────────────────────────────────────────────────────────────────

local RADIO_DETECT_RADIUS = 10   -- nodes – how far the NPC can "hear" the radio
local RADIO_CHECK_INTERVAL = 1.0 -- seconds between radio checks
local DANCE_DRIFT_SPEED    = 0.45 -- nodes/sec lateral drift while dancing
local MODEL_FILE    = "breakdancer.b3d"
local MODEL_SCALE   = 1.0
local NAMETAG_COLOR = "#FFD700"  -- golden name tag
local ANIMATION_FPS = 15.0

-- Nodes that trigger dancing when placed nearby
local DANCE_NODES = {
    "ve_radio:radio",
    "djdeck:mixer",
    "djdeck:turntable",
    "djdeck:loudspeaker",
}

-- ──────────────────────────────────────────────────────────────────────────────
-- NAMES
-- ──────────────────────────────────────────────────────────────────────────────

local spanish_breakdancer_firstnames = {
    "Alejandro", "Mateo",   "Javier",  "Carlos",  "Diego",
    "Pablo",     "Hugo",    "Álvaro",  "Daniel",  "Lucas",
    "Manuel",    "David",   "Adrián",  "Marc",    "Sergio",
    "Raúl",      "Iker",    "Bruno",   "Nicolás", "Thiago",
    "Lucía",     "Sofía",   "Martina", "Valeria", "Elena",
}

-- ──────────────────────────────────────────────────────────────────────────────
-- TEXTURE VARIANTS  (4 styles)
-- ──────────────────────────────────────────────────────────────────────────────

local textures = {
    "breakdancer.png",    -- style 1: green/blue (original)
    "breakdancer_2.png",  -- style 2: red/orange hoodie
    "breakdancer_3.png",  -- style 3: purple/gold tracksuit
    "breakdancer_4.png",  -- style 4: cyan/white jacket
}

-- ──────────────────────────────────────────────────────────────────────────────
-- DANCE MOVE TABLE  (with B3D frame ranges)
-- ──────────────────────────────────────────────────────────────────────────────

local dance_moves = {
    -- Shuffle / Melbourne Shuffle
    { name = "T-Step",      category = "shuffle",     start_frame = 31,  end_frame = 60  },
    { name = "Running Man", category = "shuffle",     start_frame = 61,  end_frame = 90  },
    { name = "Heel-Toe",    category = "shuffle",     start_frame = 91,  end_frame = 120 },
    { name = "Side Step",   category = "shuffle",     start_frame = 121, end_frame = 150 },
    { name = "Glide",       category = "shuffle",     start_frame = 151, end_frame = 180 },

    -- Breakdance / B-boying
    { name = "Six-Step",    category = "breakdance",  start_frame = 181, end_frame = 220 },
    { name = "Windmill",    category = "breakdance",  start_frame = 221, end_frame = 270 },
    { name = "Flare",       category = "breakdance",  start_frame = 271, end_frame = 320 },
    { name = "Baby Freeze", category = "breakdance",  start_frame = 321, end_frame = 360 },
    { name = "Swipe",       category = "breakdance",  start_frame = 361, end_frame = 400 },
    { name = "Headspin",    category = "breakdance",  start_frame = 401, end_frame = 450 },

    -- Streetdance / Hip-Hop
    { name = "The Wave",         category = "streetdance", start_frame = 451, end_frame = 490 },
    { name = "The Cabbage Patch",category = "streetdance", start_frame = 491, end_frame = 530 },
}

local idle_anim = { start_frame = 1, end_frame = 30 }

-- ──────────────────────────────────────────────────────────────────────────────
-- HELPER: check for radio nearby
-- ──────────────────────────────────────────────────────────────────────────────

local function is_radio_nearby(pos)
    local r = RADIO_DETECT_RADIUS
    -- Use find_node_near with a list of nodes for efficiency
    local found = minetest.find_node_near(pos, r, DANCE_NODES)
    return found ~= nil
end

-- ──────────────────────────────────────────────────────────────────────────────
-- HELPER: pick a random dance move (excludes current if possible)
-- ──────────────────────────────────────────────────────────────────────────────

local function pick_random_move(current_idx)
    if #dance_moves == 1 then return 1 end
    local idx
    repeat
        idx = math.random(1, #dance_moves)
    until idx ~= current_idx
    return idx
end

-- ──────────────────────────────────────────────────────────────────────────────
-- NPC ENTITY DEFINITION
-- ──────────────────────────────────────────────────────────────────────────────

minetest.register_entity("breakdance_npc:dancer", {
    -- --- visual ---
    visual           = "mesh",
    mesh             = MODEL_FILE,
    textures         = { textures[1] },
    visual_size      = { x = MODEL_SCALE, y = MODEL_SCALE },
    -- Entity origin sits at foot level (y=0 = ground)
    collisionbox     = { -0.3,  0.0, -0.3,  0.3,  2.0,  0.3 },
    selectionbox     = { -0.3,  0.0, -0.3,  0.3,  2.0,  0.3 },
    pointable        = true,

    -- --- physics ---
    physical         = true,
    collide_with_objects = false,
    stepheight       = 0.6,
    automatic_face_movement_dir = false,

    -- --- persistence ---
    static_save      = true,

    -- --- internal state (persisted via get_staticdata/on_staticdata) ---
    npc_name         = "",
    texture_idx      = 1,
    dancing          = false,
    current_move_idx = 0,
    radio_timer      = 0.0,

    -- ── on_activate ──────────────────────────────────────────────────────────
    on_activate = function(self, staticdata, dtime_s)
        -- Restore persisted state
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.npc_name         = data.npc_name         or ""
                self.texture_idx      = data.texture_idx      or 1
                self.dancing          = false  -- always start from idle on reload
                self.current_move_idx = data.current_move_idx or 0
            end
        end

        -- Assign new random identity if spawning fresh
        if self.npc_name == "" then
            self.npc_name    = spanish_breakdancer_firstnames[
                                    math.random(#spanish_breakdancer_firstnames)]
            self.texture_idx = math.random(#textures)
        end

        -- Store initial spawn position as dance origin
        self.dance_origin = self.object:get_pos()

        -- Apply appearance
        self.object:set_properties({
            textures  = { textures[self.texture_idx] },
            nametag   = self.npc_name,
            nametag_color = NAMETAG_COLOR,
        })

        -- Start idle animation
        self.object:set_animation(
            { x = idle_anim.start_frame, y = idle_anim.end_frame },
            ANIMATION_FPS, 0, true)

        self.radio_timer = 0.0

        -- Make sure entity is not floating (snap to below)
        self.object:set_velocity({x=0, y=0, z=0})
        self.object:set_acceleration({x=0, y=-10, z=0})
    end,

    -- ── get_staticdata ───────────────────────────────────────────────────────
    get_staticdata = function(self)
        return minetest.serialize({
            npc_name         = self.npc_name,
            texture_idx      = self.texture_idx,
            current_move_idx = self.current_move_idx,
        })
    end,

    -- ── on_step ──────────────────────────────────────────────────────────────
    on_step = function(self, dtime)
        -- Accumulate timer for radio check
        self.radio_timer = self.radio_timer + dtime
        if self.radio_timer < RADIO_CHECK_INTERVAL then return end
        self.radio_timer = 0.0

        -- Keep gravity active every tick
        self.object:set_acceleration({x=0, y=-10, z=0})

        local pos = self.object:get_pos()
        if not pos then return end

        local radio_present = is_radio_nearby(pos)

        if radio_present and not self.dancing then
            -- ── Start dancing ──
            self.dancing     = true
            self.dance_origin = pos  -- remember where we started
            self.current_move_idx = pick_random_move(0)
            local move = dance_moves[self.current_move_idx]
            self.object:set_animation(
                { x = move.start_frame, y = move.end_frame },
                ANIMATION_FPS, 0, true)
            -- Give initial drift
            self:_apply_dance_drift(pos)

            minetest.log("action",
                "[breakdance_npc] " .. self.npc_name ..
                " starts dancing: " .. move.name)

        elseif radio_present and self.dancing then
            -- ── Already dancing – pick next move and new drift direction ──
            local prev_idx = self.current_move_idx
            self.current_move_idx = pick_random_move(prev_idx)
            local move = dance_moves[self.current_move_idx]
            self.object:set_animation(
                { x = move.start_frame, y = move.end_frame },
                ANIMATION_FPS, 0, true)
            self:_apply_dance_drift(pos)

        elseif not radio_present and self.dancing then
            -- ── Radio gone – return to idle, stop moving ──
            self.dancing = false
            self.current_move_idx = 0
            self.object:set_animation(
                { x = idle_anim.start_frame, y = idle_anim.end_frame },
                ANIMATION_FPS, 0, true)
            -- Stop lateral drift
            local vel = self.object:get_velocity() or {y=0}
            self.object:set_velocity({x=0, y=vel.y, z=0})

            minetest.log("action",
                "[breakdance_npc] " .. self.npc_name .. " stops dancing.")
        end
        -- (not radio_present and not dancing → stay idle, nothing to do)
    end,

    -- ── _apply_dance_drift ───────────────────────────────────────────────────
    -- Sets a random small lateral velocity so the dancer drifts ~1 block.
    -- Stays within ~1.5 nodes of dance_origin to avoid wandering too far.
    _apply_dance_drift = function(self, pos)
        local origin = self.dance_origin

        -- Candidate drift directions (N/S/E/W)
        local candidates = {
            {x =  1, z =  0},
            {x = -1, z =  0},
            {x =  0, z =  1},
            {x =  0, z = -1},
        }

        -- If we've drifted far, bias back toward origin
        local dx = pos.x - (origin and origin.x or pos.x)
        local dz = pos.z - (origin and origin.z or pos.z)
        local dist = math.sqrt(dx*dx + dz*dz)

        local chosen
        if dist > 1.5 then
            -- Force a return direction toward origin
            chosen = {x = -dx/dist, z = -dz/dist}
        else
            chosen = candidates[math.random(#candidates)]
        end

        local vel = self.object:get_velocity() or {y=0}
        self.object:set_velocity({
            x = chosen.x * DANCE_DRIFT_SPEED,
            y = vel.y,
            z = chosen.z * DANCE_DRIFT_SPEED,
        })
    end,

    -- ── on_rightclick ────────────────────────────────────────────────────────
    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local move_str = "idle"
        if self.dancing and self.current_move_idx > 0 then
            local move = dance_moves[self.current_move_idx]
            move_str = move.name .. " [" .. move.category .. "]"
        end
        minetest.chat_send_player(clicker:get_player_name(),
            "¡Hola! Soy " .. self.npc_name ..
            " | Style #" .. self.texture_idx ..
            " | Move: " .. move_str)
    end,

    -- ── on_punch ─────────────────────────────────────────────────────────────
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        -- NPCs are invincible (decorative)
        return
    end,
})

-- ──────────────────────────────────────────────────────────────────────────────
-- SPAWN ITEM
-- ──────────────────────────────────────────────────────────────────────────────

minetest.register_craftitem("breakdance_npc:spawn_dancer", {
    description      = "Spawn Breakdancer NPC",
    inventory_image  = "breakdancer.png",
    stack_max        = 10,

    on_place = function(itemstack, placer, pointed_thing)
        if not placer or not placer:is_player() then return end
        if pointed_thing.type ~= "node" then return end

        -- pointed_thing.above is the air block directly above the surface.
        -- Entity origin = foot level, so place it at the top face of the
        -- surface node, which is exactly pointed_thing.above.y.
        local pos = vector.new(
            pointed_thing.above.x,
            pointed_thing.above.y,  -- NO +0.5: origin is at feet
            pointed_thing.above.z)
        minetest.add_entity(pos, "breakdance_npc:dancer")

        if not minetest.is_creative_enabled(placer:get_player_name()) then
            itemstack:take_item()
        end
        return itemstack
    end,
})

-- ──────────────────────────────────────────────────────────────────────────────
-- CRAFT RECIPE
-- ──────────────────────────────────────────────────────────────────────────────

minetest.register_craft({
    output = "breakdance_npc:spawn_dancer",
    recipe = {
        { "",                   "default:diamond", ""                  },
        { "default:gold_ingot", "default:stick",   "default:gold_ingot"},
        { "",                   "default:diamond", ""                  },
    },
})

-- ──────────────────────────────────────────────────────────────────────────────
-- CHAT COMMAND: /spawnbd  (quick debug spawn)
-- ──────────────────────────────────────────────────────────────────────────────

minetest.register_chatcommand("spawnbd", {
    description = "Spawn a breakdancer NPC at your position",
    privs       = { interact = true },
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found."
        end
        -- Player:get_pos() returns foot level; entity origin is also foot level
        local pos = player:get_pos()
        pos.y = pos.y  -- no offset needed
        minetest.add_entity(pos, "breakdance_npc:dancer")
        return true, "¡Vamos! A breakdancer has arrived."
    end,
})

-- ──────────────────────────────────────────────────────────────────────────────
minetest.log("action", "[breakdance_npc] Mod loaded – ¡A bailar!")
