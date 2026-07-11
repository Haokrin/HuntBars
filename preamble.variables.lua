local _, fluffy = ...

fluffy.is_casting_autoshot = false;

fluffy.current_addon_version = 250;
fluffy.client_version = 0;
fluffy.is_player_hunter = false;
fluffy.player_id = nil;
fluffy.last_update = 0;
fluffy.time_loaded = 0;

fluffy.spell_id_aimed = 19434;
fluffy.spell_id_multi = 2643;
fluffy.spell_id_arcane = 3044;
fluffy.spell_id_auto = 75;
fluffy.spell_id_FD = 5384;
fluffy.spell_id_steady = 34120;
fluffy.spell_id_raptor = 2973;
fluffy.spell_id_readiness = 23989;

-- haste buffs
fluffy.haste_id_quick_shots                             = 6150;
fluffy.haste_id_rapid_fire                              = 3045;
fluffy.haste_id_berserking                              = 20554;
fluffy.haste_id_heroism                                 = 32182;
fluffy.haste_id_bloodlust                               = 2825;
fluffy.haste_id_abacus_of_the_violent_odds              = 33807;
fluffy.haste_id_haste_potion                            = 28507;
fluffy.haste_id_hammer_haste                            = 21165;
fluffy.haste_id_dragonspine_trophy                      = 34774;
fluffy.haste_id_crowd_pummeler                          = 13494;
fluffy.haste_id_jackhammer                              = 13533;
fluffy.haste_id_drums1                                  = 35476;


-- fluffy.haste_buffs_table[buff_id] = {expiration_time, value, is_rating, type}
-- type:
-- 1 = melee
-- 2 = ranged
-- 3 = both
fluffy.haste_buffs_table = {};

fluffy.haste_buffs_table[fluffy.haste_id_quick_shots]                           = {0, 1.0, false, 2};
fluffy.haste_buffs_table[fluffy.haste_id_bloodlust]                             = {0, 1.3, false, 3};
fluffy.haste_buffs_table[fluffy.haste_id_heroism]                               = {0, 1.3, false, 3};
fluffy.haste_buffs_table[fluffy.haste_id_berserking]                            = {0, 1.1, false, 3};
fluffy.haste_buffs_table[fluffy.haste_id_rapid_fire]                            = {0, 1.4, false, 2};
fluffy.haste_buffs_table[fluffy.haste_id_haste_potion]                          = {0, 400, true, 3};
fluffy.haste_buffs_table[fluffy.haste_id_hammer_haste]                          = {0, 212, true, 3};
fluffy.haste_buffs_table[fluffy.haste_id_abacus_of_the_violent_odds]            = {0, 260, true, 3};
fluffy.haste_buffs_table[fluffy.haste_id_dragonspine_trophy]                    = {0, 325, true, 3};
fluffy.haste_buffs_table[fluffy.haste_id_crowd_pummeler]                        = {0, 500, true, 3};
fluffy.haste_buffs_table[fluffy.haste_id_jackhammer]                            = {0, 300, true, 3};
fluffy.haste_buffs_table[fluffy.haste_id_drums1]                                = {0, 80, true, 3};

-- bonuses from talents
fluffy.ranged_crit_modifier = 0;
fluffy.ranged_modifier = 1;
fluffy.melee_modifier = 1;
fluffy.multishot_modifier = 1;
fluffy.multishot_crit_bonus = 0;
fluffy.raptor_crit_bonus = 0;
fluffy.hit_bonus = 0;
fluffy.arcane_cd_reduction = 0;
fluffy.serpent_swiftness = 1;

-- ranged weapon stats
fluffy.ammo_dps = 0;
fluffy.rap = 0;
fluffy.quiver_haste = 0;
fluffy.ranged_dmg_min = 0;
fluffy.ranged_dmg_max = 0;
fluffy.ranged_dmg_avg = 0;
fluffy.ranged_base_speed = 0;
fluffy.ranged_weapon_id = 0;

-- melee weapon stats
fluffy.melee_dmg_avg_main = 0;
fluffy.main_hand_base_speed = 1;
fluffy.melee_dmg_avg_off = 0;
fluffy.off_hand_base_speed = 1;
fluffy.map = 0;
fluffy.melee_mh_weapon_id = 0;
fluffy.melee_oh_weapon_id = 0;


-- general variables for UI
fluffy.msg_color_caution = "AAE74C3C";
fluffy.msg_color_ok = "AA27AE60";
fluffy.msg_color_info = "AA3498DB";
fluffy.msg_color_error = "AAFF0000";

fluffy.bar_len_seconds = 3.4;
fluffy.movement_spark_interval = 0.5;

-- ---------------------------------------------------------------------------
-- Latency compensation (two values, used for different purposes)
--
-- GetNetStats() returns home/world ROUND-TRIP latency in ms, refreshed every
-- 0.5 s with exponential smoothing (alpha=0.3).
--
-- fluffy.latency (one-way, RTT/2, clamped [0.025, 0.25] s):
--   Added to cast_finishes so we never recommend the next GCD before the
--   server has registered the current cast.  Window STARTS being slightly
--   late is harmless — the client's spell queue absorbs early presses.
--
-- fluffy.latency_rtt (full RTT, clamped [0.05, 0.4] s):
--   Subtracted from the safe-press DEADLINE (window ends) before an incoming
--   auto shot.  Full RTT is required here, not one-way: the addon's whole
--   timeline is anchored to combat-log event ARRIVAL times (already one-way
--   late relative to the server), and a keypress takes another one-way to
--   reach the server.  press + (client->server) + cast must finish before
--   the server-side aim start = displayed_aim_start - (server->client).
--   Using only RTT/2 here makes every press at the shown window end clip
--   the auto shot by the missing half.
-- ---------------------------------------------------------------------------
fluffy.latency            = 0.05;  -- seconds one-way, default until first measurement
fluffy.latency_rtt        = 0.1;   -- seconds round-trip, default until first measurement
fluffy.latency_last_check = 0;     -- GetTime() stamp of last GetNetStats() call
fluffy.latency_color_threshold_green = 0.05;  -- 50 ms one-way (100 ms RTT)
fluffy.latency_color_threshold_yellow = 0.1;  -- 100 ms one-way (200 ms RTT)

-- ---------------------------------------------------------------------------
-- Rotation mode (updated every frame from effective weapon speed)
-- eWS = base_speed * haste_mod = cdb(t) + cast(t) = full attack period.
-- Bands are read from the best-rotation crossings in the BM and SV
-- DPS-over-haste graphs on diziet559.github.io/rotationtools:
--   eWS >= 2.4s (no Serpent's Swiftness) -> "ShortFrench" (5:4:1:1, SV base)
--   eWS >= 1.95s ->  "French"     (5:5:1:1 - BM base / SV with Hawk proc)
--   1.65-1.95s   ->  "LongFrench" (5:6:1:1 - BM with Hawk proc)
--   1.45-1.65s   ->  "1:1"        (BM with RF or Lust)
--   1.05-1.45s   ->  "Skipping"   (5:9:1:1 - BM RF+Hawk or RF+Lust)
--   0.85-1.05s   ->  "2:3"        (BM RF+Hawk+Lust)
--   0.70-0.85s   ->  "1:2"        (BM RF+Lust+Pot)
--   0.62-0.70s   ->  "2:5"        (BM RF+(Hawk|DST)+Lust+Pot)
--   < 0.62s      ->  "1:3"        (full stacking, beyond P1 reach)
-- The derivation lives in recommendation_calculation.lua
-- (fluffy.derive_rotation_mode) and is verified by the offline harness.
-- ---------------------------------------------------------------------------
fluffy.rotation_mode = "French";
fluffy.rotation_ews  = 0;

-- Time budget for one full melee weave (step in, swing, step out).  The
-- rotation overview: "Even slow weavers will manage to stay below 0.4
-- seconds weaving time".  Melee windows are clipped so a weave started
-- inside [aim_start - weave_time - latency_rtt, fire] is never suggested,
-- because moving during the 0.5 s aim delays the auto shot and ranged
-- damage has priority over weaving.
fluffy.weave_time = 0.4;

-- Set to true by combat log handlers when next_start changes.
-- The gui_Update loop checks this and forces an immediate logic
-- recalculation instead of waiting for the 20 fps throttle.
fluffy.logic_dirty = false;

-- Absolute time at which Multi-Shot is (or becomes) ready; math.huge while
-- Multi is unknown, disabled, or out of mana.  Set by analyze_game_state.
-- The renderer recolors Steady windows that Multi can claim: the steady
-- slot doubles as the Multi-Shot slot when Multi is off cooldown.
fluffy.multi_ready_at = math.huge;

-- Toggled by /fluffy debug.  When on, every auto shot prints measured vs
-- modeled aim time, fire-to-fire cycle vs eWS, and the prediction error,
-- so timing accuracy can be verified in-game.
fluffy.debug_output = false;

-- Smooth correction applied to spark positions when autoshot fires.
-- Tracks the prediction error and decays over several frames to prevent
-- the visual jump when transitioning from one auto shot cycle to the next.
fluffy.spark_correction = 0;

-- Aim (cast) duration the in-flight auto shot was scheduled with, derived
-- as next_fired - next_start each frame.  Haste changes mid-swing do NOT
-- affect the shot already in flight — the server applies the new speed
-- from the next shot onward — so the first spark, the first gap's aim
-- window, and the weave clipping all use this stored value instead of the
-- current attack speed.
fluffy.scheduled_aim = 0;

-- Tracks the last time an event caused a state change, so the OOC idle
-- freeze can continue updating long enough for cooldowns to expire.
fluffy.last_dirty_time = 0;

-- Previous frame's first two spark positions, used to detect visual
-- jumps (from haste changes or fire events) and smooth them.
fluffy.prev_spark_1 = 0;
fluffy.prev_spark_2 = 0;

-- Overdue-freeze state: when autoshot should have fired but didn't,
-- bars freeze in place instead of rolling back.
fluffy.autoshot_frozen = false;
fluffy.freeze_time = 0;

fluffy.spell_color_steady = "FFFC9803"; -- 252, 152, 3
fluffy.spell_color_multi = "FF0386FC"; -- 3, 134, 254
fluffy.spell_color_arcane = "FFaf7ac5"; -- 175, 122, 197 
fluffy.spell_color_raptor = "FF27ae60"; --39, 174, 96
fluffy.spell_color_melee = "FFd5d8dc"; -- 213, 216, 220
fluffy.spell_color_auto = "FFFF0000"; -- 255, 0, 0

fluffy.icon_path_auto = "Interface\\ICONS\\ability_whirlwind";
fluffy.icon_path_aimed = "Interface\\ICONS\\INV_Spear_07";
fluffy.icon_path_multi = "Interface\\ICONS\\Ability_UpgradeMoonGlaive";
fluffy.icon_path_arcane = "Interface\\ICONS\\Ability_ImpalingBolt";
fluffy.icon_path_steady = "Interface\\ICONS\\Ability_hunter_steadyshot";
fluffy.icon_path_raptor = "Interface\\ICONS\\ability_meleedamage";
fluffy.icon_path_melee = "Interface\\ICONS\\ability_meleedamage";





