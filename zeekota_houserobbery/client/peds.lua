ZeeKotaPeds = ZeeKotaPeds or {}

local contactPed
local contactBlip
local armedPeds = {}
local deadReports = {}

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end

    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end

    return HasModelLoaded(hash) and hash or nil
end

local function cleanupEntity(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

function ZeeKotaPeds.SpawnContact()
    if not Config.ContactPed.enabled or contactPed then return end

    local hash = loadModel(Config.ContactPed.model)
    if not hash then return end

    local coords = Config.ContactPed.coords
    contactPed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityAsMissionEntity(contactPed, true, true)
    SetBlockingOfNonTemporaryEvents(contactPed, true)
    SetEntityInvincible(contactPed, true)
    FreezeEntityPosition(contactPed, true)

    if Config.ContactPed.scenario then
        TaskStartScenarioInPlace(contactPed, Config.ContactPed.scenario, 0, true)
    end

    if Config.ContactPed.blip.enabled then
        contactBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(contactBlip, Config.ContactPed.blip.sprite)
        SetBlipColour(contactBlip, Config.ContactPed.blip.color)
        SetBlipScale(contactBlip, Config.ContactPed.blip.scale)
        SetBlipAsShortRange(contactBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.ContactPed.blip.label)
        EndTextCommandSetBlipName(contactBlip)
    end

    SetModelAsNoLongerNeeded(hash)
end

function ZeeKotaPeds.CleanupContact()
    cleanupEntity(contactPed)
    contactPed = nil

    if contactBlip then
        RemoveBlip(contactBlip)
        contactBlip = nil
    end
end

local function armPed(ped)
    local weapons = Config.ArmedPeds.weapons
    local weapon = weapons[math.random(1, #weapons)]
    GiveWeaponToPed(ped, joaat(weapon), 180, false, true)
    SetPedArmour(ped, Config.ArmedPeds.armor)
    SetPedAccuracy(ped, Config.ArmedPeds.accuracy)
    SetEntityHealth(ped, Config.ArmedPeds.health)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAbility(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedCombatRange(ped, 2)
    SetPedFleeAttributes(ped, 0, false)
end

function ZeeKotaPeds.SpawnArmed(house)
    ZeeKotaPeds.CleanupArmed()
    if not Config.ArmedPeds.enabled or not house then return 0 end

    local tier = house.tier or 1
    local maxCount = Config.ArmedPeds.spawnByTier[tier] or 0
    local chance = Config.ArmedPeds.chanceByTier[tier] or 0
    if maxCount <= 0 or not ZeeKotaBridge.RandomChance(chance) then return 0 end

    local spawns = house.pedSpawns or {}
    local count = math.min(maxCount, #spawns)
    if count <= 0 then return 0 end

    for index = 1, count do
        local spawn = spawns[index]
        local model = Config.ArmedPeds.models[math.random(1, #Config.ArmedPeds.models)]
        local hash = loadModel(model)

        if hash then
            local ped = CreatePed(4, hash, spawn.x, spawn.y, spawn.z, spawn.w or 0.0, true, true)
            SetEntityAsMissionEntity(ped, true, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            armPed(ped)

            if Config.ArmedPeds.hostile then
                TaskCombatPed(ped, PlayerPedId(), 0, 16)
            end

            armedPeds[#armedPeds + 1] = ped
            SetModelAsNoLongerNeeded(hash)
        end
    end

    if #armedPeds > 0 then
        ZeeKotaBridge.Notify(nil, Config.Notifications.armedDetected)
    end

    return #armedPeds
end

function ZeeKotaPeds.CleanupArmed()
    for _, ped in ipairs(armedPeds) do
        cleanupEntity(ped)
    end
    armedPeds = {}
    deadReports = {}
end

CreateThread(function()
    while true do
        local sleep = 1000

        if #armedPeds > 0 then
            sleep = 500
            for _, ped in ipairs(armedPeds) do
                if DoesEntityExist(ped) and IsEntityDead(ped) and not deadReports[ped] then
                    deadReports[ped] = true
                    TriggerServerEvent(('%s:server:armedPedKilled'):format(Config.ResourceName))
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ZeeKotaPeds.CleanupContact()
    ZeeKotaPeds.CleanupArmed()
end)
