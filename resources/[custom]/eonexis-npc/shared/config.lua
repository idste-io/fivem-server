Config = {}

-- Police patrol routes (when no police player on duty)
Config.PolicePatrols = {
    { x = 441.3,  y = -982.0, z = 30.6,  h = 0.0   },
    { x = 460.0,  y = -995.0, z = 27.0,  h = 90.0  },
    { x = 430.0,  y = -975.0, z = 30.0,  h = 180.0 },
    { x = 420.0,  y = -960.0, z = 28.0,  h = 270.0 },
}

-- How many NPC cops to keep on patrol when no real cop is online
Config.MinPoliceNPCs = 2

-- Job-specific companion NPC configs
Config.JobNPCs = {
    taxi = {
        model  = 'a_m_m_business_01',
        action = 'wander',  -- wander near job center
        radius = 30.0,
    },
    delivery = {
        model  = 'a_m_y_vinewood_01',
        action = 'wander',
        radius = 25.0,
    },
    mechanic = {
        model  = 's_m_y_xmech_01',
        action = 'wander',
        radius = 20.0,
    },
    trucker = {
        model  = 's_m_y_trucker_01',
        action = 'wander',
        radius = 40.0,
    },
    fisher = {
        model  = 'a_m_o_beach_01',
        action = 'wander',
        radius = 15.0,
    },
    guard = {
        model  = 's_m_m_security_01',
        action = 'stand',   -- stand at post
        radius = 5.0,
    },
}

-- Job center position (where NPCs gather)
Config.JobCenterPos = vector3(128.0, -1043.0, 29.0)

-- Police station position
Config.PoliceStationPos = vector3(441.3, -982.0, 30.6)
