local ActiveRobberies = {}
local PlayerCooldowns = {}
local HouseCooldowns = {}
local GlobalCooldown = 0

local function notify(source, key, override)
    local data = {}
    local base = Config.Notifications[key] or Config.Notifications.invalid
    for k, v in pairs(base or {}) do data[k] = v end
    for k, v in pairs(override or {}) do data[k] = v end
    ZeeKotaBridge.Notify(source, data)
end

local function houseById(houseId)
    houseId = tonumber(houseId)
    return houseId and Config.Houses[houseId], houseId
end

local function distanceBetween(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

local function playerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function isNear(source, coords, radius)
    local current = playerCoords(source)
    if not current then return false end
    return distanceBetween(current, coords) <= (radius or 4.0)
end

local function remainingUntil(timestamp)
    return math.max(0, math.floor((timestamp or 0) - os.time()))
end

local function cooldownFor(identifier, houseId, stats)
    if not Config.Cooldowns.enabled then return 0 end

    local remaining = 0
    remaining = math.max(remaining, remainingUntil(GlobalCooldown))
    remaining = math.max(remaining, remainingUntil(PlayerCooldowns[identifier]))
    remaining = math.max(remaining, remainingUntil(HouseCooldowns[houseId]))

    if Config.Cooldowns.perPlayer.enabled and stats and tonumber(stats.last_robbery_at or 0) > 0 then
        local duration = Config.Cooldowns.perPlayer.minutes * 60
        remaining = math.max(remaining, remainingUntil((tonumber(stats.last_robbery_at) or 0) + duration))
    end

    return remaining
end

local function setCooldowns(identifier, houseId, minutes)
    if not Config.Cooldowns.enabled then return end
    local now = os.time()
    local playerMinutes = minutes or Config.Cooldowns.defaultMinutes

    if Config.Cooldowns.perPlayer.enabled then
        PlayerCooldowns[identifier] = now + (playerMinutes * 60)
    end

    if Config.Cooldowns.perHouse.enabled then
        local house = Config.Houses[houseId]
        local houseMinutes = (house and house.cooldown) or Config.Cooldowns.perHouse.minutes
        HouseCooldowns[houseId] = now + (houseMinutes * 60)
    end

    if Config.Cooldowns.global.enabled then
        GlobalCooldown = now + (Config.Cooldowns.global.minutes * 60)
    end
end

local function publicHouse(houseId, house, stats)
    local level = tonumber(stats.current_level) or 1
    local requiredLevel = house.requiredLevel or Config.Progression.levelRequiredByTier[house.tier] or 1
    local cooldown = cooldownFor(stats.identifier, houseId, stats)
    local unlocked = level >= requiredLevel

    return {
        id = houseId,
        label = house.label,
        description = house.description,
        tier = house.tier,
        requiredLevel = requiredLevel,
        requiredItem = house.requiredItem,
        interior = house.interior,
        cooldown = cooldown,
        unlocked = unlocked,
        lockedReason = unlocked and nil or ('Level %s required'):format(requiredLevel),
        entrance = ZeeKotaBridge.TrimVector4(house.entrance),
        lootCount = #(house.lootZones or {}),
        dispatchAlertChance = house.dispatchAlertChance or Config.Dispatch.alertChance
    }
end

local function publicStats(stats)
    local levelData = ZeeKotaDB.levelForXP(stats.total_xp or 0)
    return {
        identifier = stats.identifier,
        displayName = stats.display_name,
        housesBrokenInto = tonumber(stats.houses_broken_into) or 0,
        successfulRobberies = tonumber(stats.successful_robberies) or 0,
        failedRobberies = tonumber(stats.failed_robberies) or 0,
        cancelledRobberies = tonumber(stats.cancelled_robberies) or 0,
        totalLootValue = tonumber(stats.total_loot_value) or 0,
        bestRobberyValue = tonumber(stats.best_robbery_value) or 0,
        totalXP = tonumber(stats.total_xp) or 0,
        currentLevel = levelData.level,
        failedKeypadAttempts = tonumber(stats.failed_keypad_attempts) or 0,
        armedPedsKilled = tonumber(stats.armed_peds_killed) or 0,
        timesPoliceAlerted = tonumber(stats.times_police_alerted) or 0,
        currentStreak = tonumber(stats.current_streak) or 0,
        highestStreak = tonumber(stats.highest_streak) or 0,
        levelData = levelData
    }
end

local function publicActive(source)
    local active = ActiveRobberies[source]
    if not active then return nil end

    return {
        houseId = active.houseId,
        houseLabel = active.house.label,
        tier = active.house.tier,
        stage = active.stage,
        searched = active.searchedCount,
        lootValue = active.lootValue,
        alarmed = active.alarmed,
        startedAt = active.startedAt
    }
end

local function canStart(source, houseId)
    local house = Config.Houses[houseId]
    if not house then return false, 'invalid' end
    if ActiveRobberies[source] then return false, 'alreadyActive' end

    local identifier = ZeeKotaDB.ensurePlayer(source)
    if not identifier then return false, 'invalid' end

    local stats = ZeeKotaDB.getStats(identifier)
    stats.identifier = identifier

    local policeCount = ZeeKotaBridge.GetPoliceCount()
    if Config.PoliceRequirement.enabled and policeCount < Config.PoliceRequirement.required then
        return false, 'notEnoughPolice', { policeCount = policeCount, requiredPolice = Config.PoliceRequirement.required }
    end

    local cooldown = cooldownFor(identifier, houseId, stats)
    if cooldown > 0 then
        return false, 'cooldown', { cooldown = cooldown }
    end

    local requiredLevel = house.requiredLevel or Config.Progression.levelRequiredByTier[house.tier] or 1
    if (tonumber(stats.current_level) or 1) < requiredLevel then
        return false, 'levelLow', { requiredLevel = requiredLevel }
    end

    local requiredItem = house.requiredItem or Config.Lockpick.requiredItem
    if requiredItem and not ZeeKotaBridge.HasItem(source, requiredItem, 1) then
        return false, 'missingItem', { item = requiredItem }
    end

    return true, nil, {
        identifier = identifier,
        stats = stats,
        house = house,
        policeCount = policeCount
    }
end

local function finishRobbery(source, options)
    local active = ActiveRobberies[source]
    if not active then return false, 'invalid' end

    options = options or {}
    local success = options.success
    if success == nil then
        success = active.searchedCount >= Config.Completion.minLootSpots
        if Config.Completion.requireLoot then
            success = success and active.searchedCount > 0
        end
    end

    local cancelled = options.cancelled == true
    local xp = 0

    if success then
        xp = ZeeKotaRewards.CalculateXP(active.house, active.lootValue, active.alarmed)
    elseif cancelled then
        xp = Config.Progression.cancelledXP
    else
        xp = Config.Progression.failedXP
    end

    if active.pedsKilled > 0 then
        ZeeKotaDB.recordPedKills(active.identifier, active.pedsKilled)
    end

    local completion = {
        action = cancelled and 'cancelled' or (success and 'completed' or 'failed'),
        success = success,
        cancelled = cancelled,
        houseId = active.houseId,
        tier = active.house.tier,
        lootValue = active.lootValue,
        searchedCount = active.searchedCount,
        alarmed = active.alarmed,
        pedsKilled = active.pedsKilled,
        xp = xp
    }
    local result = ZeeKotaDB.completeRobbery(active.identifier, completion) or completion

    local cooldownMinutes = nil
    if cancelled and Config.Cooldowns.cancelPenalty.enabled then
        cooldownMinutes = Config.Cooldowns.cancelPenalty.minutes
    end
    setCooldowns(active.identifier, active.houseId, cooldownMinutes)

    ActiveRobberies[source] = nil

    if Config.Dispatch.triggers.completion and success then
        ZeeKotaDispatch.TryAlert(source, active.identifier, 'Robbery completion', active.house, Config.Dispatch.alertChance, active.house.entrance)
    end

    return true, nil, result
end

local function buildDashboard(source)
    local identifier = ZeeKotaDB.ensurePlayer(source)
    if not identifier then return { ok = false, error = 'No identifier' } end

    local stats = ZeeKotaDB.getStats(identifier)
    stats.identifier = identifier

    local houses = {}
    for houseId, house in pairs(Config.Houses) do
        houses[#houses + 1] = publicHouse(houseId, house, stats)
    end
    table.sort(houses, function(a, b) return a.id < b.id end)

    local policeCount = ZeeKotaBridge.GetPoliceCount()

    return {
        ok = true,
        brand = Config.UI,
        framework = ZeeKotaBridge.FrameworkName(),
        police = {
            count = policeCount,
            required = Config.PoliceRequirement.required,
            enough = not Config.PoliceRequirement.enabled or policeCount >= Config.PoliceRequirement.required,
            jobs = Config.PoliceJobs
        },
        stats = publicStats(stats),
        houses = houses,
        active = publicActive(source),
        config = {
            cooldowns = Config.Cooldowns,
            progression = Config.Progression,
            dispatch = Config.Dispatch,
            lockpick = Config.Lockpick
        }
    }
end

ZeeKotaBridge.RegisterCallback('server:getDashboard', function(source)
    return buildDashboard(source)
end)

ZeeKotaBridge.RegisterCallback('server:startRobbery', function(source, houseId)
    local house
    house, houseId = houseById(houseId)
    local allowed, reason, data = canStart(source, houseId)
    if not allowed then
        notify(source, reason)
        return { ok = false, reason = reason, data = data }
    end

    ActiveRobberies[source] = {
        identifier = data.identifier,
        houseId = houseId,
        house = house,
        stage = 'assigned',
        assignedAt = os.time(),
        startedAt = 0,
        failedAttempts = 0,
        searchedZones = {},
        searchedCount = 0,
        lootValue = 0,
        alarmed = false,
        pedsKilled = 0
    }

    notify(source, 'started')

    return {
        ok = true,
        robbery = {
            houseId = houseId,
            label = house.label,
            tier = house.tier,
            entrance = ZeeKotaBridge.TrimVector4(house.entrance),
            interiorSpawn = ZeeKotaBridge.TrimVector4(house.interiorSpawn),
            exit = ZeeKotaBridge.TrimVector4(house.exit),
            stage = 'assigned'
        }
    }
end)

ZeeKotaBridge.RegisterCallback('server:doorResult', function(source, houseId, success)
    local active = ActiveRobberies[source]
    local house
    house, houseId = houseById(houseId)

    if not active or not house or active.houseId ~= houseId or active.stage ~= 'assigned' then
        notify(source, 'invalid')
        return { ok = false, reason = 'invalid' }
    end

    if not isNear(source, house.entrance, 8.0) then
        notify(source, 'invalid', { description = 'You are too far from the door.' })
        return { ok = false, reason = 'distance' }
    end

    if success then
        if Config.Lockpick.consumeOnStart then
            ZeeKotaBridge.RemoveItem(source, house.requiredItem or Config.Lockpick.requiredItem, 1)
        elseif Config.Lockpick.removeOnSuccess then
            ZeeKotaBridge.RemoveItem(source, house.requiredItem or Config.Lockpick.requiredItem, 1)
        end

        active.stage = 'inside'
        active.startedAt = os.time()
        ZeeKotaDB.recordDoorBreach(active.identifier)
        notify(source, 'breachSuccess')

        local doorAlert = false
        if Config.Dispatch.triggers.doorBreach then
            doorAlert = ZeeKotaDispatch.TryAlert(source, active.identifier, 'Door breach', house, house.dispatchAlertChance, house.entrance)
        end

        local entryAlert = false
        if Config.Dispatch.triggers.enteredInterior and not doorAlert then
            entryAlert = ZeeKotaDispatch.TryAlert(source, active.identifier, 'Suspicious residential entry', house, Config.Dispatch.alertChance, house.entrance)
        end

        local alerted = doorAlert or entryAlert

        if alerted then
            active.alarmed = true
            notify(source, 'dispatchAlerted')
        end

        return {
            ok = true,
            enter = true,
            alert = alerted,
            interiorSpawn = ZeeKotaBridge.TrimVector4(house.interiorSpawn),
            exit = ZeeKotaBridge.TrimVector4(house.exit)
        }
    end

    active.failedAttempts = active.failedAttempts + 1
    ZeeKotaDB.recordFailedKeypad(active.identifier)
    notify(source, 'breachFailed')

    if Config.Lockpick.breakOnFailure and ZeeKotaBridge.RandomChance(Config.Lockpick.breakChanceOnFailure) then
        ZeeKotaBridge.RemoveItem(source, house.requiredItem or Config.Lockpick.requiredItem, 1)
    end

    local alert = false
    if Config.Dispatch.triggers.failedMinigame then
        alert = ZeeKotaDispatch.TryAlert(source, active.identifier, 'Failed keypad bypass', house, house.dispatchAlertChance, house.entrance)
    end

    if alert then
        active.alarmed = true
        notify(source, 'dispatchAlerted')
    end

    if Config.Lockpick.cancelAfterFailLimit and active.failedAttempts >= Config.Lockpick.failLimit then
        local _, _, result = finishRobbery(source, { success = false })
        if result then
            result.dashboard = buildDashboard(source)
        end
        return { ok = true, failed = true, cancelled = true, result = result }
    end

    return {
        ok = true,
        failed = true,
        attempts = active.failedAttempts,
        failLimit = Config.Lockpick.failLimit,
        alert = alert
    }
end)

ZeeKotaBridge.RegisterCallback('server:searchLoot', function(source, zoneIndex)
    local active = ActiveRobberies[source]
    if not active or active.stage ~= 'inside' then
        notify(source, 'invalid')
        return { ok = false, reason = 'invalid' }
    end

    zoneIndex = tonumber(zoneIndex)
    local zone = active.house.lootZones and active.house.lootZones[zoneIndex]
    if not zone then
        return { ok = false, reason = 'invalidZone' }
    end

    if active.searchedZones[zoneIndex] then
        return { ok = false, reason = 'alreadySearched' }
    end

    if not isNear(source, zone.coords, (zone.radius or 1.2) + 2.0) then
        return { ok = false, reason = 'distance' }
    end

    if zone.requiredItem and not ZeeKotaBridge.HasItem(source, zone.requiredItem, 1) then
        notify(source, 'missingItem', { description = ('You need %s for this spot.'):format(zone.requiredItem) })
        return { ok = false, reason = 'missingItem' }
    end

    active.searchedZones[zoneIndex] = true
    active.searchedCount = active.searchedCount + 1

    local rewards, value = ZeeKotaRewards.Roll(source, active.house, zone)
    active.lootValue = active.lootValue + value

    local alert = false
    if Config.Dispatch.triggers.noisyLoot and zone.policeAlertChance then
        alert = ZeeKotaDispatch.TryAlert(source, active.identifier, 'Noisy search reported', active.house, zone.policeAlertChance, zone.coords)
    end

    if alert then
        active.alarmed = true
        notify(source, 'dispatchAlerted')
    end

    if #rewards > 0 then
        notify(source, 'lootFound')
    else
        notify(source, 'nothingFound')
    end

    return {
        ok = true,
        zoneIndex = zoneIndex,
        rewards = rewards,
        value = value,
        totalValue = active.lootValue,
        searchedCount = active.searchedCount,
        alert = alert
    }
end)

ZeeKotaBridge.RegisterCallback('server:completeRobbery', function(source)
    local active = ActiveRobberies[source]
    if not active or active.stage ~= 'inside' then
        notify(source, 'invalid')
        return { ok = false, reason = 'invalid' }
    end

    if not isNear(source, active.house.exit, 8.0) then
        notify(source, 'invalid', { description = 'Move to the configured exit first.' })
        return { ok = false, reason = 'distance' }
    end

    local ok, reason, result = finishRobbery(source)
    if ok then
        notify(source, result.success and 'completed' or 'failed')
        result.dashboard = buildDashboard(source)
    end

    return { ok = ok, reason = reason, result = result }
end)

ZeeKotaBridge.RegisterCallback('server:cancelRobbery', function(source)
    local active = ActiveRobberies[source]
    if not active then
        return { ok = false, reason = 'none' }
    end

    local ok, reason, result = finishRobbery(source, { success = false, cancelled = true })
    if ok then
        notify(source, 'cancelled')
        result.dashboard = buildDashboard(source)
        TriggerClientEvent(('%s:client:forceCleanup'):format(Config.ResourceName), source)
    end

    return { ok = ok, reason = reason, result = result }
end)

RegisterNetEvent(('%s:server:armedPedKilled'):format(Config.ResourceName), function()
    local src = source
    local active = ActiveRobberies[src]
    if active then
        active.pedsKilled = active.pedsKilled + 1
        if Config.Dispatch.triggers.gunfire then
            local alerted = ZeeKotaDispatch.TryAlert(src, active.identifier, 'Gunfire inside residence', active.house, 100, active.house.entrance)
            if alerted then active.alarmed = true end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if ActiveRobberies[src] then
        finishRobbery(src, { success = false, cancelled = true })
    end
end)
