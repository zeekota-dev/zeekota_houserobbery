ZeeKotaClientDispatch = ZeeKotaClientDispatch or {}

local function coordsFromPayload(data)
    local coords = data.coords or {}
    return vector3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
end

local function streetName(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local crossing = crossingHash and crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
    if crossing and crossing ~= '' then
        return ('%s / %s'):format(street, crossing)
    end
    return street ~= '' and street or 'Unknown street'
end

local function cdDispatch(data, coords, message)
    return pcall(function()
        local playerInfo = exports['cd_dispatch']:GetPlayerInfo()
        exports['cd_dispatch']:AddNotification({
            job_table = data.jobs,
            coords = coords,
            title = data.title,
            message = message,
            flash = 0,
            unique_id = tostring(math.random(100000, 999999)),
            sound = 1,
            blip = {
                sprite = 40,
                scale = 1.15,
                colour = 1,
                flashes = false,
                text = data.title,
                time = data.blipDuration,
                radius = 0
            },
            information = playerInfo
        })
    end)
end

local function qsDispatch(data, coords, message)
    return pcall(function()
        TriggerServerEvent('qs-dispatch:server:CreateDispatchCall', {
            job = data.jobs,
            callLocation = coords,
            callCode = { code = data.code, snippet = data.title },
            message = message,
            flashes = false,
            image = nil,
            blip = {
                sprite = 40,
                scale = 1.15,
                colour = 1,
                flashes = false,
                text = data.title,
                time = data.blipDuration * 1000
            }
        })
    end)
end

local function psDispatch(data, coords, message)
    return pcall(function()
        exports['ps-dispatch']:CustomAlert({
            coords = coords,
            message = message,
            dispatchCode = data.code,
            description = data.description,
            radius = 0,
            sprite = 40,
            color = 1,
            scale = 1.15,
            length = data.blipDuration
        })
    end)
end

RegisterNetEvent(('%s:client:dispatchAlert'):format(Config.ResourceName), function(data)
    local coords = coordsFromPayload(data)
    local location = streetName(coords)
    local message = ('%s near %s'):format(data.description or data.title, location)
    local system = data.system or Config.Dispatch.system
    local ok = false

    if system == 'cd_dispatch' then
        ok = cdDispatch(data, coords, message)
    elseif system == 'qs-dispatch' or system == 'qs_dispatch' then
        ok = qsDispatch(data, coords, message)
    elseif system == 'ps-dispatch' or system == 'ps_dispatch' then
        ok = psDispatch(data, coords, message)
    elseif system == 'custom' and data.customClientEvent then
        TriggerEvent(data.customClientEvent, data, coords, message)
        ok = true
    end

    if not ok and data.customClientEvent then
        TriggerEvent(data.customClientEvent, data, coords, message)
    end
end)
