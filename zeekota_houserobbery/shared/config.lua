Config = {}

Config.Framework = 'auto' -- auto, esx, qbcore
Config.Debug = false
Config.ResourceName = 'zeekota_houserobbery'

Config.Commands = {
    cancel = 'cancelhouserobbery'
}

Config.UsableMenuItem = {
    enabled = false,
    item = 'robbery_planner'
}

Config.UI = {
    title = 'ZeeKota House Robbery',
    subtitle = 'ZeeKota Residential Division',
    moneyPrefix = '$',
    refreshSeconds = 30,
    showTierLootRanges = true
}

Config.ContactPed = {
    enabled = true,
    model = 'g_m_m_chigoon_02',
    coords = vector4(-1194.12, -1189.74, 7.69, 188.0),
    scenario = 'WORLD_HUMAN_SMOKING',
    blip = {
        enabled = true,
        sprite = 40,
        color = 1,
        scale = 0.8,
        label = 'ZeeKota Robbery Contact'
    },
    interaction = {
        distance = 5.0,
        key = 38,
        keyLabel = 'E',
        text = 'Press E to Open ZeeKota Menu'
    }
}

Config.DoorInteraction = {
    distance = 2.0,
    key = 38,
    keyLabel = 'E',
    text = 'Press E to Lock Pick Door'
}

Config.LootInteraction = {
    key = 38,
    keyLabel = 'E',
    textPrefix = 'Press E to',
    animation = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer'
    }
}

Config.Progression = {
    maxLevel = 30,
    baseXPPerLevel = 900,
    xpGrowth = 1.18,
    successXP = 180,
    failedXP = 25,
    cancelledXP = 0,
    stealthBonusXP = 90,
    alarmPenaltyXP = -45,
    lootXPValueDivisor = 120,
    tierXP = {
        [1] = 80,
        [2] = 150,
        [3] = 260,
        [4] = 410,
        [5] = 650
    },
    levelRequiredByTier = {
        [1] = 1,
        [2] = 4,
        [3] = 8,
        [4] = 14,
        [5] = 22
    },
    lootMultiplierByTier = {
        [1] = 1.0,
        [2] = 1.25,
        [3] = 1.55,
        [4] = 1.9,
        [5] = 2.35
    }
}

Config.PoliceJobs = {
    'police',
    'sheriff',
    'state'
}

Config.PoliceRequirement = {
    enabled = true,
    required = 2,
    countDutyOnly = true
}

Config.Cooldowns = {
    enabled = true,
    defaultMinutes = 30,
    global = {
        enabled = false,
        minutes = 5
    },
    perHouse = {
        enabled = true,
        minutes = 45
    },
    perPlayer = {
        enabled = true,
        minutes = 30
    },
    cancelPenalty = {
        enabled = true,
        minutes = 10
    }
}

Config.Completion = {
    requireLoot = true,
    minLootSpots = 1,
    failedIfAlarmAndNoLoot = true,
    cancelledCountsAsFailed = true
}

Config.Dispatch = {
    enabled = true,
    system = 'cd_dispatch', -- cd_dispatch, qs-dispatch, ps-dispatch, custom
    alertChance = 50,
    blipDuration = 60,
    jobs = { 'police', 'sheriff', 'state' },
    code = '10-90',
    title = 'ZeeKota House Robbery',
    customClientEvent = 'zeekota_houserobbery:client:customDispatch',
    triggers = {
        failedMinigame = true,
        doorBreach = true,
        enteredInterior = true,
        noisyLoot = true,
        gunfire = true,
        completion = false
    }
}

Config.Lockpick = {
    requiredItem = 'lockpick',
    consumeOnStart = false,
    removeOnSuccess = false,
    breakOnFailure = true,
    breakChanceOnFailure = 35,
    failLimit = 3,
    cancelAfterFailLimit = true,
    difficulties = {
        [1] = { duration = 18000, sequenceLength = 4, failTiles = 2, attemptsRequired = 1 },
        [2] = { duration = 17000, sequenceLength = 5, failTiles = 3, attemptsRequired = 1 },
        [3] = { duration = 16000, sequenceLength = 6, failTiles = 4, attemptsRequired = 2 },
        [4] = { duration = 15000, sequenceLength = 7, failTiles = 5, attemptsRequired = 2 },
        [5] = { duration = 14000, sequenceLength = 8, failTiles = 6, attemptsRequired = 3 }
    }
}

Config.Interiors = {
    fadeMs = 500,
    requestIpls = {
        'apa_v_mp_h_01_a',
        'apa_v_mp_h_01_c',
        'apa_v_mp_h_08_c'
    },
    exitText = '[E] Leave Property'
}

Config.ArmedPeds = {
    enabled = true,
    models = { 'g_m_m_chigoon_02', 'g_m_y_mexgoon_02', 'g_m_y_ballaeast_01' },
    weapons = { 'WEAPON_PISTOL', 'WEAPON_SMG', 'WEAPON_PUMPSHOTGUN' },
    armor = 25,
    accuracy = 35,
    health = 180,
    aggressionRange = 32.0,
    hostile = true,
    spawnByTier = {
        [1] = 0,
        [2] = 1,
        [3] = 1,
        [4] = 2,
        [5] = 3
    },
    chanceByTier = {
        [1] = 0,
        [2] = 15,
        [3] = 35,
        [4] = 70,
        [5] = 95
    }
}

Config.Rewards = {
    useFrameworkMoney = false,
    frameworkMoneyAccount = 'cash',
    moneyItem = 'money',
    dirtyMoneyItem = 'black_money',
    canCarryValidation = true,
    itemValues = {
        money = 1,
        black_money = 1,
        rolex = 850,
        diamond_ring = 2400,
        goldchain = 650,
        laptop = 1250,
        tablet = 900,
        markedbills = 1,
        goldbar = 6500,
        antique_coin = 3200,
        luxury_watch = 4200,
        ruby_necklace = 8500
    }
}

Config.Notifications = {
    notEnoughPolice = { title = 'ZeeKota House Robbery', description = 'There is not enough police pressure in the city.', type = 'error' },
    cooldown = { title = 'ZeeKota House Robbery', description = 'You are still cooling down from the last job.', type = 'error' },
    levelLow = { title = 'ZeeKota House Robbery', description = 'Your robbery level is too low for this contract.', type = 'error' },
    missingItem = { title = 'ZeeKota House Robbery', description = 'You are missing the required entry tool.', type = 'error' },
    started = { title = 'Contract Accepted', description = 'Waypoint set. Keep it quiet.', type = 'success' },
    breachSuccess = { title = 'Door Bypassed', description = 'The keypad accepted the bypass. Get inside.', type = 'success' },
    breachFailed = { title = 'Bypass Failed', description = 'The keypad locked you out.', type = 'error' },
    dispatchAlerted = { title = 'Dispatch Alerted', description = 'A patrol alert was transmitted.', type = 'warning' },
    lootFound = { title = 'Loot Secured', description = 'You found valuables.', type = 'success' },
    nothingFound = { title = 'Nothing Found', description = 'This spot was empty.', type = 'inform' },
    completed = { title = 'Robbery Complete', description = 'The house is cleared and your stats were updated.', type = 'success' },
    failed = { title = 'Robbery Failed', description = 'The job ended without meeting completion requirements.', type = 'error' },
    cancelled = { title = 'Robbery Cancelled', description = 'The active robbery was cancelled.', type = 'warning' },
    armedDetected = { title = 'Armed Occupants', description = 'You are not alone in here.', type = 'warning' },
    alreadyActive = { title = 'Active Robbery', description = 'You already have a robbery in progress.', type = 'error' },
    invalid = { title = 'ZeeKota House Robbery', description = 'That robbery action is not valid right now.', type = 'error' }
}

Config.Houses = {
    [1] = {
        label = 'Low-End Apartment',
        description = 'A quiet starter unit with light valuables and short search windows.',
        tier = 1,
        requiredLevel = 1,
        requiredItem = 'lockpick',
        entrance = vector4(-1077.74, -1026.42, 4.54, 120.0),
        interiorSpawn = vector4(266.05, -1007.33, -101.01, 357.0),
        exit = vector4(265.94, -1002.91, -99.01, 182.0),
        doorHeading = 120.0,
        interior = 'low_end_apartment',
        cooldown = 30,
        dispatchAlertChance = 25,
        lootZones = {
            {
                coords = vector3(262.86, -1002.74, -99.01),
                radius = 1.2,
                label = 'Search Drawer',
                duration = 5000,
                animation = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
                loot = {
                    { item = 'money', min = 500, max = 1500, chance = 80 },
                    { item = 'rolex', min = 1, max = 2, chance = 20 },
                    { item = 'goldchain', min = 1, max = 1, chance = 25 }
                }
            },
            {
                coords = vector3(265.93, -999.37, -99.01),
                radius = 1.3,
                label = 'Search Kitchen Cabinet',
                duration = 5500,
                policeAlertChance = 5,
                loot = {
                    { item = 'money', min = 350, max = 900, chance = 75 },
                    { item = 'tablet', min = 1, max = 1, chance = 8 }
                }
            },
            {
                coords = vector3(259.74, -1004.02, -99.01),
                radius = 1.1,
                label = 'Search Nightstand',
                duration = 4500,
                loot = {
                    { item = 'money', min = 300, max = 700, chance = 65 },
                    { item = 'diamond_ring', min = 1, max = 1, chance = 6 }
                }
            }
        },
        pedSpawns = {}
    },
    [2] = {
        label = 'Vespucci Medium Home',
        description = 'Better take, more rooms, and a small chance of armed occupants.',
        tier = 2,
        requiredLevel = 4,
        requiredItem = 'lockpick',
        entrance = vector4(-1106.24, -1687.43, 4.37, 307.0),
        interiorSpawn = vector4(346.55, -1012.78, -99.20, 355.0),
        exit = vector4(346.61, -1012.85, -99.20, 181.0),
        doorHeading = 307.0,
        interior = 'mid_apartment',
        cooldown = 35,
        dispatchAlertChance = 35,
        lootZones = {
            {
                coords = vector3(351.16, -999.22, -99.20),
                radius = 1.3,
                label = 'Search Entertainment Stand',
                duration = 6500,
                loot = {
                    { item = 'money', min = 850, max = 2200, chance = 78 },
                    { item = 'laptop', min = 1, max = 1, chance = 22 },
                    { item = 'tablet', min = 1, max = 1, chance = 18 }
                }
            },
            {
                coords = vector3(350.91, -993.56, -99.20),
                radius = 1.2,
                label = 'Search Bedroom Dresser',
                duration = 6200,
                policeAlertChance = 8,
                loot = {
                    { item = 'rolex', min = 1, max = 3, chance = 30 },
                    { item = 'diamond_ring', min = 1, max = 1, chance = 14 },
                    { item = 'money', min = 500, max = 1400, chance = 70 }
                }
            },
            {
                coords = vector3(342.41, -1003.28, -99.20),
                radius = 1.2,
                label = 'Search Office Desk',
                duration = 6000,
                requiredItem = nil,
                loot = {
                    { item = 'money', min = 600, max = 1800, chance = 65 },
                    { item = 'markedbills', min = 1200, max = 3200, chance = 18 }
                }
            }
        },
        pedSpawns = {
            vector4(350.65, -996.03, -99.20, 95.0)
        }
    },
    [3] = {
        label = 'Richman Luxury Apartment',
        description = 'Luxury apartment interior with high-value jewelry and noisy search spots.',
        tier = 3,
        requiredLevel = 8,
        requiredItem = 'advancedlockpick',
        entrance = vector4(-765.62, 650.44, 145.70, 110.0),
        interiorSpawn = vector4(-786.87, 315.75, 217.64, 268.0),
        exit = vector4(-786.78, 315.78, 217.64, 92.0),
        doorHeading = 110.0,
        interior = 'high_end_apartment',
        cooldown = 45,
        dispatchAlertChance = 50,
        lootZones = {
            {
                coords = vector3(-795.75, 326.37, 217.04),
                radius = 1.4,
                label = 'Search Jewelry Cabinet',
                duration = 8000,
                policeAlertChance = 15,
                loot = {
                    { item = 'diamond_ring', min = 1, max = 3, chance = 35 },
                    { item = 'luxury_watch', min = 1, max = 2, chance = 25 },
                    { item = 'money', min = 1800, max = 4200, chance = 80 }
                }
            },
            {
                coords = vector3(-793.49, 331.64, 217.04),
                radius = 1.3,
                label = 'Search Bedroom Safe',
                duration = 9000,
                requiredItem = 'drill',
                policeAlertChance = 22,
                loot = {
                    { item = 'markedbills', min = 3500, max = 8000, chance = 50 },
                    { item = 'goldbar', min = 1, max = 1, chance = 12 },
                    { item = 'ruby_necklace', min = 1, max = 1, chance = 8 }
                }
            },
            {
                coords = vector3(-781.92, 326.52, 217.04),
                radius = 1.2,
                label = 'Search Office',
                duration = 7600,
                loot = {
                    { item = 'laptop', min = 1, max = 2, chance = 32 },
                    { item = 'money', min = 900, max = 2600, chance = 72 },
                    { item = 'antique_coin', min = 1, max = 1, chance = 8 }
                }
            }
        },
        pedSpawns = {
            vector4(-793.65, 326.08, 217.04, 120.0),
            vector4(-781.45, 326.25, 217.04, 240.0)
        }
    },
    [4] = {
        label = 'Vinewood High-End House',
        description = 'Armed high-end property with rare loot and stronger dispatch risk.',
        tier = 4,
        requiredLevel = 14,
        requiredItem = 'advancedlockpick',
        entrance = vector4(-1539.89, 420.59, 110.01, 356.0),
        interiorSpawn = vector4(-174.36, 497.67, 137.65, 191.0),
        exit = vector4(-174.36, 497.67, 137.65, 191.0),
        doorHeading = 356.0,
        interior = 'vinewood_house',
        cooldown = 60,
        dispatchAlertChance = 65,
        lootZones = {
            {
                coords = vector3(-170.73, 486.69, 137.44),
                radius = 1.4,
                label = 'Search Trophy Wall',
                duration = 8500,
                policeAlertChance = 20,
                loot = {
                    { item = 'goldbar', min = 1, max = 2, chance = 18 },
                    { item = 'antique_coin', min = 1, max = 2, chance = 25 },
                    { item = 'money', min = 2500, max = 6200, chance = 76 }
                }
            },
            {
                coords = vector3(-167.54, 488.19, 133.84),
                radius = 1.3,
                label = 'Search Master Closet',
                duration = 9000,
                loot = {
                    { item = 'luxury_watch', min = 1, max = 3, chance = 40 },
                    { item = 'ruby_necklace', min = 1, max = 1, chance = 16 },
                    { item = 'markedbills', min = 4500, max = 9500, chance = 45 }
                }
            },
            {
                coords = vector3(-174.18, 493.34, 130.04),
                radius = 1.3,
                label = 'Search Wine Storage',
                duration = 8200,
                policeAlertChance = 16,
                loot = {
                    { item = 'money', min = 1800, max = 4800, chance = 65 },
                    { item = 'goldbar', min = 1, max = 1, chance = 12 }
                }
            }
        },
        pedSpawns = {
            vector4(-168.82, 492.45, 137.65, 70.0),
            vector4(-172.16, 489.87, 133.84, 220.0),
            vector4(-176.41, 493.15, 130.04, 18.0)
        }
    },
    [5] = {
        label = 'Elite Hills Estate',
        description = 'Top-shelf estate contract with multiple armed occupants and elite rewards.',
        tier = 5,
        requiredLevel = 22,
        requiredItem = 'advancedlockpick',
        entrance = vector4(-2587.76, 1910.89, 167.50, 275.0),
        interiorSpawn = vector4(1397.02, 1141.86, 114.33, 92.0),
        exit = vector4(1397.02, 1141.86, 114.33, 92.0),
        doorHeading = 275.0,
        interior = 'elite_estate',
        cooldown = 75,
        dispatchAlertChance = 80,
        lootZones = {
            {
                coords = vector3(1393.11, 1139.79, 114.33),
                radius = 1.5,
                label = 'Search Display Vault',
                duration = 10000,
                requiredItem = 'drill',
                policeAlertChance = 35,
                loot = {
                    { item = 'ruby_necklace', min = 1, max = 2, chance = 28 },
                    { item = 'goldbar', min = 1, max = 3, chance = 24 },
                    { item = 'markedbills', min = 9000, max = 18000, chance = 60 }
                }
            },
            {
                coords = vector3(1400.35, 1159.74, 114.33),
                radius = 1.4,
                label = 'Search Private Office',
                duration = 9500,
                policeAlertChance = 22,
                loot = {
                    { item = 'laptop', min = 1, max = 2, chance = 38 },
                    { item = 'antique_coin', min = 1, max = 3, chance = 30 },
                    { item = 'money', min = 3500, max = 9000, chance = 78 }
                }
            },
            {
                coords = vector3(1406.79, 1147.74, 114.33),
                radius = 1.4,
                label = 'Search Master Suite',
                duration = 9200,
                loot = {
                    { item = 'luxury_watch', min = 2, max = 4, chance = 42 },
                    { item = 'diamond_ring', min = 1, max = 3, chance = 38 },
                    { item = 'ruby_necklace', min = 1, max = 1, chance = 18 }
                }
            }
        },
        pedSpawns = {
            vector4(1399.57, 1147.08, 114.33, 250.0),
            vector4(1406.13, 1152.52, 114.33, 170.0),
            vector4(1390.91, 1132.54, 114.33, 34.0),
            vector4(1404.96, 1139.71, 114.33, 282.0)
        }
    }
}
