ZeeKotaDispatch = ZeeKotaDispatch or {}

local function buildPayload(reason, house, coords)
    return {
        reason = reason,
        system = Config.Dispatch.system,
        jobs = Config.Dispatch.jobs,
        code = Config.Dispatch.code,
        title = Config.Dispatch.title,
        description = ('%s reported at %s. Tier %s property.'):format(reason, house.label, house.tier),
        houseLabel = house.label,
        houseTier = house.tier,
        coords = ZeeKotaBridge.TrimVector3(coords or house.entrance),
        blipDuration = Config.Dispatch.blipDuration,
        customClientEvent = Config.Dispatch.customClientEvent
    }
end

function ZeeKotaDispatch.TryAlert(source, identifier, reason, house, chance, coords)
    if not Config.Dispatch.enabled then return false end
    if not house then return false end

    local finalChance = chance
    if finalChance == nil then
        finalChance = house.dispatchAlertChance or Config.Dispatch.alertChance
    end

    if not ZeeKotaBridge.RandomChance(finalChance) then return false end

    local payload = buildPayload(reason, house, coords)
    TriggerClientEvent(('%s:client:dispatchAlert'):format(Config.ResourceName), source, payload)

    if identifier then
        ZeeKotaDB.recordPoliceAlert(identifier)
    end

    return true
end
