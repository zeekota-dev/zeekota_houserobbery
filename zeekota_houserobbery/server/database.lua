ZeeKotaDB = ZeeKotaDB or {}

local MemoryStats = {}
local warnedNoProvider = false

local function provider()
    if GetResourceState('oxmysql') == 'started' then
        return 'oxmysql'
    end

    if MySQL and MySQL.Async then
        return 'mysql-async'
    end

    return nil
end

local function warnNoProvider()
    if warnedNoProvider then return end
    warnedNoProvider = true
    print(('[%s] No supported MySQL provider found. Stats will use temporary memory until oxmysql or mysql-async is available.'):format(Config.ResourceName))
end

local function awaitMysqlAsync(method, query, params)
    local p = promise.new()
    MySQL.Async[method](query, params or {}, function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

local function awaitOxmysql(method, query, params, fallback)
    local p = promise.new()
    local ok, err = pcall(function()
        if method == 'query' then
            exports.oxmysql:query(query, params or {}, function(result)
                p:resolve(result)
            end)
        elseif method == 'scalar' then
            exports.oxmysql:scalar(query, params or {}, function(result)
                p:resolve(result)
            end)
        elseif method == 'update' then
            exports.oxmysql:update(query, params or {}, function(result)
                p:resolve(result)
            end)
        elseif method == 'execute' then
            exports.oxmysql:execute(query, params or {}, function(result)
                p:resolve(result)
            end)
        end
    end)

    if not ok then
        if method == 'update' then
            return awaitOxmysql('execute', query, params, fallback)
        end

        print(('[%s] oxmysql %s failed: %s'):format(Config.ResourceName, method, err))
        return fallback
    end

    local result = Citizen.Await(p)
    if result == nil then return fallback end
    return result
end

function ZeeKotaDB.query(query, params)
    local current = provider()
    params = params or {}

    if current == 'oxmysql' and MySQL and MySQL.query and MySQL.query.await then
        return MySQL.query.await(query, params) or {}
    end

    if current == 'oxmysql' then
        return awaitOxmysql('query', query, params, {}) or {}
    end

    if current == 'mysql-async' then
        return awaitMysqlAsync('fetchAll', query, params) or {}
    end

    warnNoProvider()
    return {}
end

function ZeeKotaDB.scalar(query, params)
    local current = provider()
    params = params or {}

    if current == 'oxmysql' and MySQL and MySQL.scalar and MySQL.scalar.await then
        return MySQL.scalar.await(query, params)
    end

    if current == 'oxmysql' then
        return awaitOxmysql('scalar', query, params, nil)
    end

    if current == 'mysql-async' then
        return awaitMysqlAsync('fetchScalar', query, params)
    end

    local rows = ZeeKotaDB.query(query, params)
    if rows[1] then
        for _, value in pairs(rows[1]) do
            return value
        end
    end

    return nil
end

function ZeeKotaDB.execute(query, params)
    local current = provider()
    params = params or {}

    if current == 'oxmysql' and MySQL and MySQL.update and MySQL.update.await then
        return MySQL.update.await(query, params) or 0
    end

    if current == 'oxmysql' then
        return awaitOxmysql('update', query, params, 0) or 0
    end

    if current == 'mysql-async' then
        return awaitMysqlAsync('execute', query, params) or 0
    end

    warnNoProvider()
    return 0
end

local function levelThreshold(level)
    if level <= 1 then return 0 end

    local total = 0
    local base = Config.Progression.baseXPPerLevel
    local growth = Config.Progression.xpGrowth

    for currentLevel = 2, level do
        total = total + math.floor(base * (growth ^ (currentLevel - 2)))
    end

    return total
end

function ZeeKotaDB.levelForXP(xp)
    xp = math.max(0, math.floor(tonumber(xp) or 0))
    local level = 1

    for currentLevel = 1, Config.Progression.maxLevel do
        if xp >= levelThreshold(currentLevel) then
            level = currentLevel
        else
            break
        end
    end

    local currentThreshold = levelThreshold(level)
    local nextThreshold = level < Config.Progression.maxLevel and levelThreshold(level + 1) or currentThreshold
    local span = math.max(1, nextThreshold - currentThreshold)

    return {
        level = level,
        totalXP = xp,
        currentLevelXP = math.max(0, xp - currentThreshold),
        nextLevelXP = nextThreshold,
        xpForNextLevel = math.max(0, nextThreshold - xp),
        progress = level >= Config.Progression.maxLevel and 100 or math.floor(((xp - currentThreshold) / span) * 100)
    }
end

local function defaultStats(identifier, displayName, framework)
    return {
        identifier = identifier,
        framework = framework or ZeeKotaBridge.FrameworkName(),
        display_name = displayName or 'Unknown',
        houses_broken_into = 0,
        successful_robberies = 0,
        failed_robberies = 0,
        cancelled_robberies = 0,
        total_loot_value = 0,
        best_robbery_value = 0,
        total_xp = 0,
        current_level = 1,
        failed_keypad_attempts = 0,
        armed_peds_killed = 0,
        times_police_alerted = 0,
        current_streak = 0,
        highest_streak = 0,
        last_robbery_at = 0
    }
end

function ZeeKotaDB.ensurePlayer(source)
    local identifier = ZeeKotaBridge.GetIdentifier(source)
    if not identifier then return nil end

    local displayName = ZeeKotaBridge.GetPlayerName(source)
    local framework = ZeeKotaBridge.FrameworkName()

    if not provider() then
        local stats = MemoryStats[identifier] or defaultStats(identifier, displayName, framework)
        stats.framework = framework
        stats.display_name = displayName
        stats.updated_at = os.time()
        MemoryStats[identifier] = stats
        warnNoProvider()
        return identifier
    end

    ZeeKotaDB.execute([[
        INSERT INTO zeekota_houserobbery_players
            (identifier, framework, display_name, current_level, total_xp, created_at, updated_at)
        VALUES
            (?, ?, ?, 1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
        ON DUPLICATE KEY UPDATE
            framework = VALUES(framework),
            display_name = VALUES(display_name),
            updated_at = UNIX_TIMESTAMP()
    ]], { identifier, framework, displayName })

    return identifier
end

function ZeeKotaDB.getStats(identifier)
    if not identifier then return nil end

    if not provider() then
        MemoryStats[identifier] = MemoryStats[identifier] or defaultStats(identifier)
        return MemoryStats[identifier]
    end

    local rows = ZeeKotaDB.query('SELECT * FROM zeekota_houserobbery_players WHERE identifier = ? LIMIT 1', { identifier })
    local row = rows[1]
    if not row then
        return defaultStats(identifier)
    end

    local xp = tonumber(row.total_xp) or 0
    local level = ZeeKotaDB.levelForXP(xp).level
    if tonumber(row.current_level) ~= level then
        ZeeKotaDB.execute('UPDATE zeekota_houserobbery_players SET current_level = ?, updated_at = UNIX_TIMESTAMP() WHERE identifier = ?', { level, identifier })
        row.current_level = level
    end

    return row
end

function ZeeKotaDB.recordDoorBreach(identifier)
    if not provider() then
        local stats = ZeeKotaDB.getStats(identifier)
        stats.houses_broken_into = (tonumber(stats.houses_broken_into) or 0) + 1
        stats.updated_at = os.time()
        return
    end

    ZeeKotaDB.execute([[
        UPDATE zeekota_houserobbery_players
        SET houses_broken_into = houses_broken_into + 1,
            updated_at = UNIX_TIMESTAMP()
        WHERE identifier = ?
    ]], { identifier })
end

function ZeeKotaDB.recordFailedKeypad(identifier)
    if not provider() then
        local stats = ZeeKotaDB.getStats(identifier)
        stats.failed_keypad_attempts = (tonumber(stats.failed_keypad_attempts) or 0) + 1
        stats.updated_at = os.time()
        return
    end

    ZeeKotaDB.execute([[
        UPDATE zeekota_houserobbery_players
        SET failed_keypad_attempts = failed_keypad_attempts + 1,
            updated_at = UNIX_TIMESTAMP()
        WHERE identifier = ?
    ]], { identifier })
end

function ZeeKotaDB.recordPoliceAlert(identifier)
    if not provider() then
        local stats = ZeeKotaDB.getStats(identifier)
        stats.times_police_alerted = (tonumber(stats.times_police_alerted) or 0) + 1
        stats.updated_at = os.time()
        return
    end

    ZeeKotaDB.execute([[
        UPDATE zeekota_houserobbery_players
        SET times_police_alerted = times_police_alerted + 1,
            updated_at = UNIX_TIMESTAMP()
        WHERE identifier = ?
    ]], { identifier })
end

function ZeeKotaDB.recordPedKills(identifier, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return end

    if not provider() then
        local stats = ZeeKotaDB.getStats(identifier)
        stats.armed_peds_killed = (tonumber(stats.armed_peds_killed) or 0) + amount
        stats.updated_at = os.time()
        return
    end

    ZeeKotaDB.execute([[
        UPDATE zeekota_houserobbery_players
        SET armed_peds_killed = armed_peds_killed + ?,
            updated_at = UNIX_TIMESTAMP()
        WHERE identifier = ?
    ]], { amount, identifier })
end

function ZeeKotaDB.completeRobbery(identifier, result)
    local stats = ZeeKotaDB.getStats(identifier)
    if not stats then return nil end

    local xpGain = math.max(0, math.floor(tonumber(result.xp) or 0))
    local lootValue = math.max(0, math.floor(tonumber(result.lootValue) or 0))
    local totalXP = (tonumber(stats.total_xp) or 0) + xpGain
    local levelData = ZeeKotaDB.levelForXP(totalXP)
    local successful = result.success == true
    local cancelled = result.cancelled == true
    local failed = not successful and (not cancelled or Config.Completion.cancelledCountsAsFailed)
    local currentStreak = tonumber(stats.current_streak) or 0
    local highestStreak = tonumber(stats.highest_streak) or 0

    if successful then
        currentStreak = currentStreak + 1
        highestStreak = math.max(highestStreak, currentStreak)
    elseif failed then
        currentStreak = 0
    end

    local successfulRobberies = (tonumber(stats.successful_robberies) or 0) + (successful and 1 or 0)
    local failedRobberies = (tonumber(stats.failed_robberies) or 0) + (failed and 1 or 0)
    local cancelledRobberies = (tonumber(stats.cancelled_robberies) or 0) + (cancelled and 1 or 0)
    local totalLootValue = (tonumber(stats.total_loot_value) or 0) + lootValue
    local bestRobberyValue = math.max(tonumber(stats.best_robbery_value) or 0, lootValue)
    local lastRobberyAt = os.time()

    if not provider() then
        stats.successful_robberies = successfulRobberies
        stats.failed_robberies = failedRobberies
        stats.cancelled_robberies = cancelledRobberies
        stats.total_loot_value = totalLootValue
        stats.best_robbery_value = bestRobberyValue
        stats.total_xp = totalXP
        stats.current_level = levelData.level
        stats.current_streak = currentStreak
        stats.highest_streak = highestStreak
        stats.last_robbery_at = lastRobberyAt
        stats.updated_at = lastRobberyAt
        MemoryStats[identifier] = stats
    else
        ZeeKotaDB.execute([[
            INSERT INTO zeekota_houserobbery_players
                (identifier, successful_robberies, failed_robberies, cancelled_robberies,
                 total_loot_value, best_robbery_value, total_xp, current_level,
                 current_streak, highest_streak, last_robbery_at, created_at, updated_at)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
            ON DUPLICATE KEY UPDATE
                successful_robberies = VALUES(successful_robberies),
                failed_robberies = VALUES(failed_robberies),
                cancelled_robberies = VALUES(cancelled_robberies),
                total_loot_value = VALUES(total_loot_value),
                best_robbery_value = VALUES(best_robbery_value),
                total_xp = VALUES(total_xp),
                current_level = VALUES(current_level),
                current_streak = VALUES(current_streak),
                highest_streak = VALUES(highest_streak),
                last_robbery_at = VALUES(last_robbery_at),
                updated_at = UNIX_TIMESTAMP()
        ]], {
            identifier,
            successfulRobberies,
            failedRobberies,
            cancelledRobberies,
            totalLootValue,
            bestRobberyValue,
            totalXP,
            levelData.level,
            currentStreak,
            highestStreak,
            lastRobberyAt
        })
    end

    result.totalXP = totalXP
    result.level = levelData.level
    result.levelData = levelData

    if provider() then
        ZeeKotaDB.log(identifier, result.action or (successful and 'completed' or 'failed'), result.houseId, result.tier, lootValue, xpGain, result)
    end

    return result
end

function ZeeKotaDB.log(identifier, action, houseId, tier, lootValue, xp, metadata)
    ZeeKotaDB.execute([[
        INSERT INTO zeekota_houserobbery_logs
            (identifier, action, house_id, tier, loot_value, xp, metadata, created_at)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, UNIX_TIMESTAMP())
    ]], {
        identifier,
        action,
        houseId,
        tier,
        lootValue or 0,
        xp or 0,
        json.encode(metadata or {})
    })
end
