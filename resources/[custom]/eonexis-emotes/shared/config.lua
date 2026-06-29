Config = {}

-- /e <name> — animation dictionary + clip + optional flags
-- loop=true keeps animation playing until /e stop
Config.Emotes = {
    sit      = { dict='amb@world_human_seat_wall@male@base', clip='base',              loop=true  },
    wave     = { dict='gestures@m@standing@casual',          clip='gesture_wave_hi',    loop=false },
    clap     = { dict='gestures@m@standing@casual',          clip='gesture_applaud',    loop=false },
    dance    = { dict='anim@amb@nightclub@dancers@crowddance_dance_RA', clip='hi_dance_facedj_15_v1_male^1', loop=true },
    lean     = { dict='amb@world_human_leaning@male@wall@back@foot@idle_a', clip='idle_a', loop=true },
    smoke    = { dict='amb@world_human_smoking@male@idle_a', clip='idle_a',             loop=true  },
    kneel    = { dict='amb@medic@standing@kneel@base',        clip='base',               loop=true  },
    pushups  = { dict='amb@world_human_push_ups@male@base',   clip='base',               loop=true  },
    situps   = { dict='amb@world_human_sit_ups@male@base',    clip='base',               loop=true  },
    yoga     = { dict='amb@world_human_yoga@male@base',       clip='base',               loop=true  },
    phone    = { dict='cellphone@',                           clip='cellphone_call_listen_base', loop=true },
    eat      = { dict='mp_player_int_upperbody_eating_burger_fp', clip='mp_player_int_eating_burger', loop=true },
    bow      = { dict='mp_player_int_upperbody_bowing',       clip='bow',                loop=false },
    salute   = { dict='mp_player_int_upperbody_salute',       clip='salute',             loop=false },
    finger   = { dict='gestures@m@standing@casual',           clip='gesture_middle_finger', loop=false },
    facepalm = { dict='gestures@m@standing@casual',           clip='gesture_face_palm',  loop=false },
    shrug    = { dict='gestures@m@standing@casual',           clip='gesture_shrug',      loop=false },
    point    = { dict='gestures@m@standing@casual',           clip='gesture_point',      loop=false },
    thumbsup = { dict='gestures@m@standing@casual',           clip='gesture_thumb_up',   loop=false },
    fistbump = { dict='mp_player_int_upperbody_fist_bump',    clip='fist_bump_b',        loop=false },
}
