ZeeKotaBridge = ZeeKotaBridge or {}

local resourceName = GetCurrentResourceName()
local frameworkObject
local frameworkName

local function resourceStarted(name)
    return GetResourceState(name) == 'started' or GetResourceState(name) == 'starting'
end

local function tableContains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then return true end
    end

    return false
end

function ZeeKotaBridge.Debug(message, ...)
    if not Config or not Config.Debug then return end
    local formatted = message
    if select('#', ...) > 0 then
        formatted = string.format(message, ...)
    end
    print(('[%s] %s'):format(resourceName, formatted))
end

function ZeeKotaBridge.DetectFramework()
    if frameworkName then return frameworkName, frameworkObject end

    local configured = (Config.Framework or 'auto'):lower()

    if configured == 'esx' or (configured == 'auto' and resourceStarted('es_extended')) then
        frameworkName = 'esx'
        local ok, object = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        frameworkObject = ok and object or nil
        return frameworkName, frameworkObject
    end

    if configured == 'qbcore' or configured == 'qb' or (configured == 'auto' and resourceStarted('qb-core')) then
        frameworkName = 'qbcore'
        local ok, object = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        frameworkObject = ok and object or nil
        return frameworkName, frameworkObject
    end

    return nil, nil
end

function ZeeKotaBridge.FrameworkName()
    local name = ZeeKotaBridge.DetectFramework()
    return name or 'standalone'
end

function ZeeKotaBridge.RegisterCallback(name, cb)
    lib.callback.register(('%s:%s'):format(resourceName, name), cb)
end

function ZeeKotaBridge.AwaitCallback(name, ...)
    return lib.callback.await(('%s:%s'):format(resourceName, name), false, ...)
end

function ZeeKotaBridge.Notify(target, data)
    if IsDuplicityVersion() then
        TriggerClientEvent(('%s:client:notify'):format(resourceName), target, data)
        return
    end

    data = data or {}
    lib.notify({
        title = data.title or 'ZeeKota House Robbery',
        description = data.description or data.message or '',
        type = data.type or 'inform',
        position = data.position or 'top'
    })
end

function ZeeKotaBridge.GetFrameworkPlayer(source)
    local name, object = ZeeKotaBridge.DetectFramework()
    if not name or not object then return nil, name end

    if name == 'esx' then
        return object.GetPlayerFromId(source), name
    end

    if name == 'qbcore' then
        return object.Functions.GetPlayer(source), name
    end

    return nil, name
end

local function licenseIdentifier(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find('license:', 1, true) then
            return identifier
        end
    end

    return GetPlayerIdentifier(source, 0)
end

function ZeeKotaBridge.GetIdentifier(source)
    local player, name = ZeeKotaBridge.GetFrameworkPlayer(source)

    if name == 'esx' and player then
        return player.identifier or licenseIdentifier(source)
    end

    if name == 'qbcore' and player then
        return player.PlayerData.citizenid or player.PlayerData.license or licenseIdentifier(source)
    end

    return licenseIdentifier(source)
end

function ZeeKotaBridge.GetPlayerName(source)
    local player, name = ZeeKotaBridge.GetFrameworkPlayer(source)

    if name == 'esx' and player then
        if player.getName then return player.getName() end
        return player.name or GetPlayerName(source)
    end

    if name == 'qbcore' and player then
        local info = player.PlayerData.charinfo or {}
        local fullName = ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s*(.-)%s*$', '%1')
        if fullName ~= '' then return fullName end
    end

    return GetPlayerName(source) or 'Unknown'
end

function ZeeKotaBridge.GetJob(source)
    local player, name = ZeeKotaBridge.GetFrameworkPlayer(source)

    if name == 'esx' and player then
        local job = player.job or (player.getJob and player.getJob())
        if job then
            return job.name, job.onDuty ~= false
        end
    end

    if name == 'qbcore' and player then
        local job = player.PlayerData.job or {}
        return job.name, job.onduty ~= false
    end

    return nil, false
end

function ZeeKotaBridge.GetPoliceCount()
    local count = 0

    for _, source in ipairs(GetPlayers()) do
        local jobName, onDuty = ZeeKotaBridge.GetJob(tonumber(source))
        if jobName and tableContains(Config.PoliceJobs, jobName) then
            if not Config.PoliceRequirement.countDutyOnly or onDuty then
                count = count + 1
            end
        end
    end

    return count
end

function ZeeKotaBridge.GetMoney(source, account)
    local player, name = ZeeKotaBridge.GetFrameworkPlayer(source)
    account = account or 'cash'

    if name == 'esx' and player then
        if account == 'cash' and player.getMoney then
            return player.getMoney()
        end

        local accountData = player.getAccount and player.getAccount(account)
        return accountData and accountData.money or 0
    end

    if name == 'qbcore' and player then
        return player.Functions.GetMoney(account) or 0
    end

    return 0
end

function ZeeKotaBridge.RemoveMoney(source, account, amount, reason)
    local player, name = ZeeKotaBridge.GetFrameworkPlayer(source)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    if ZeeKotaBridge.GetMoney(source, account) < amount then return false end

    if name == 'esx' and player then
        if account == 'cash' and player.removeMoney then
            player.removeMoney(amount)
        elseif player.removeAccountMoney then
            player.removeAccountMoney(account, amount)
        end
        return true
    end

    if name == 'qbcore' and player then
        return player.Functions.RemoveMoney(account, amount, reason or 'zeekota_houserobbery')
    end

    return false
end

function ZeeKotaBridge.AddMoney(source, account, amount, reason)
    local player, name = ZeeKotaBridge.GetFrameworkPlayer(source)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    if name == 'esx' and player then
        if account == 'cash' and player.addMoney then
            player.addMoney(amount)
        elseif player.addAccountMoney then
            player.addAccountMoney(account, amount)
        end
        return true
    end

    if name == 'qbcore' and player then
        return player.Functions.AddMoney(account, amount, reason or 'zeekota_houserobbery')
    end

    return false
end

function ZeeKotaBridge.GetItemCount(source, item)
    if not item or item == '' then return 0 end
    local ok, count = pcall(function()
        return exports.ox_inventory:Search(source, 'count', item)
    end)
    return ok and tonumber(count) or 0
end

function ZeeKotaBridge.HasItem(source, item, amount)
    if not item or item == '' then return true end
    return ZeeKotaBridge.GetItemCount(source, item) >= (amount or 1)
end

function ZeeKotaBridge.CanCarryItem(source, item, amount, metadata)
    if not Config.Rewards.canCarryValidation then return true end
    local ok, result = pcall(function()
        return exports.ox_inventory:CanCarryItem(source, item, amount, metadata)
    end)
    return ok and result == true
end

function ZeeKotaBridge.AddItem(source, item, amount, metadata)
    if not item or amount <= 0 then return false end
    if not ZeeKotaBridge.CanCarryItem(source, item, amount, metadata) then return false end

    local ok, result = pcall(function()
        return exports.ox_inventory:AddItem(source, item, amount, metadata)
    end)

    return ok and result ~= false
end

function ZeeKotaBridge.RemoveItem(source, item, amount, metadata)
    if not item or amount <= 0 then return true end
    local ok, result = pcall(function()
        return exports.ox_inventory:RemoveItem(source, item, amount, metadata)
    end)
    return ok and result ~= false
end

function ZeeKotaBridge.RegisterUsableItem(item, cb)
    local name, object = ZeeKotaBridge.DetectFramework()
    if not item or item == '' or not object then return false end

    if name == 'esx' and object.RegisterUsableItem then
        object.RegisterUsableItem(item, cb)
        return true
    end

    if name == 'qbcore' and object.Functions and object.Functions.CreateUseableItem then
        object.Functions.CreateUseableItem(item, function(source, itemData)
            cb(source, itemData)
        end)
        return true
    end

    return false
end

function ZeeKotaBridge.RandomChance(chance)
    return math.random(100) <= math.max(0, math.min(100, tonumber(chance) or 0))
end

function ZeeKotaBridge.TrimVector4(value)
    return {
        x = value.x,
        y = value.y,
        z = value.z,
        w = value.w or value.heading or 0.0
    }
end

function ZeeKotaBridge.TrimVector3(value)
    return {
        x = value.x,
        y = value.y,
        z = value.z
    }
end
