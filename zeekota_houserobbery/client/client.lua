ZeeKotaClient = ZeeKotaClient or {
    active = nil,
    prompt = nil,
    screenPrompt = nil,
    doorBlip = nil
}

local function vec3From(value)
    return vector3(value.x, value.y, value.z)
end

local function distanceTo(value)
    return #(GetEntityCoords(PlayerPedId()) - vec3From(value))
end

function ZeeKotaClient.HideScreenPrompt()
    if not ZeeKotaClient.screenPrompt then return end
    SendNUIMessage({
        action = 'prompt',
        visible = false
    })
    ZeeKotaClient.screenPrompt = nil
end

function ZeeKotaClient.ShowScreenPrompt(text, key)
    local prompt = {
        key = key or 'E',
        text = text or ''
    }
    local promptId = ('%s:%s'):format(prompt.key, prompt.text)

    if ZeeKotaClient.prompt then
        lib.hideTextUI()
        ZeeKotaClient.prompt = nil
    end

    if ZeeKotaClient.screenPrompt == promptId then return end
    ZeeKotaClient.screenPrompt = promptId

    SendNUIMessage({
        action = 'prompt',
        visible = true,
        key = prompt.key,
        message = prompt.text
    })
end

function ZeeKotaClient.ShowText(text)
    ZeeKotaClient.HideScreenPrompt()
    if ZeeKotaClient.prompt == text then return end
    if ZeeKotaClient.prompt then lib.hideTextUI() end
    ZeeKotaClient.prompt = text
    lib.showTextUI(text, {
        position = 'left-center',
        icon = 'house-lock',
        style = {
            borderRadius = 6,
            backgroundColor = '#050506',
            color = '#ffffff',
            border = '1px solid #ff1f2d'
        }
    })
end

function ZeeKotaClient.HideText()
    ZeeKotaClient.HideScreenPrompt()
    if not ZeeKotaClient.prompt then return end
    lib.hideTextUI()
    ZeeKotaClient.prompt = nil
end

local function clearDoorBlip()
    if ZeeKotaClient.doorBlip then
        RemoveBlip(ZeeKotaClient.doorBlip)
        ZeeKotaClient.doorBlip = nil
    end
end

local function createDoorBlip(house)
    clearDoorBlip()
    ZeeKotaClient.doorBlip = AddBlipForCoord(house.entrance.x, house.entrance.y, house.entrance.z)
    SetBlipSprite(ZeeKotaClient.doorBlip, 40)
    SetBlipColour(ZeeKotaClient.doorBlip, 1)
    SetBlipScale(ZeeKotaClient.doorBlip, 0.9)
    SetBlipRoute(ZeeKotaClient.doorBlip, true)
    SetBlipRouteColour(ZeeKotaClient.doorBlip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(house.label)
    EndTextCommandSetBlipName(ZeeKotaClient.doorBlip)
    SetNewWaypoint(house.entrance.x, house.entrance.y)
end

function ZeeKotaClient.AssignRobbery(robbery)
    local house = Config.Houses[robbery.houseId]
    if not house then return end

    ZeeKotaClient.active = {
        houseId = robbery.houseId,
        house = house,
        stage = 'assigned',
        searched = {},
        totalValue = 0
    }

    createDoorBlip(house)
    SendNUIMessage({ action = 'toast', message = 'Waypoint set. Breach the property door.', type = 'success' })
end

function ZeeKotaClient.Cleanup(teleportOutside)
    ZeeKotaClient.HideText()

    if teleportOutside and ZeeKotaClient.active and ZeeKotaClient.active.stage == 'inside' then
        ZeeKotaInteriors.TeleportOutside(ZeeKotaClient.active.house)
    end

    ZeeKotaPeds.CleanupArmed()
    clearDoorBlip()
    ZeeKotaClient.active = nil
end

local function tryDoorBreach()
    local active = ZeeKotaClient.active
    if not active or active.stage ~= 'assigned' then return end

    ZeeKotaClient.HideText()
    local success = ZeeKotaMinigame.Start(active.house.tier)
    local result = ZeeKotaBridge.AwaitCallback('server:doorResult', active.houseId, success)

    if not result or not result.ok then return end

    if result.enter then
        clearDoorBlip()
        active.stage = 'inside'
        active.searched = {}
        ZeeKotaInteriors.Enter(active.house)
        Wait(700)
        ZeeKotaPeds.SpawnArmed(active.house)
        SendNUIMessage({
            action = 'robberyState',
            payload = {
                stage = 'inside',
                houseLabel = active.house.label,
                tier = active.house.tier
            }
        })
    elseif result.cancelled then
        ZeeKotaClient.Cleanup(false)
    end
end

local function searchZone(index, zone)
    local active = ZeeKotaClient.active
    if not active or active.searched[index] then return end

    ZeeKotaClient.HideText()
    local lootInteraction = Config.LootInteraction or {}

    local progress = lib.progressBar({
        duration = zone.duration or 5000,
        label = zone.label or 'Search',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = zone.animation or lootInteraction.animation
    })

    if not progress then return end

    local result = ZeeKotaBridge.AwaitCallback('server:searchLoot', index)
    if result and result.ok then
        active.searched[index] = true
        active.totalValue = result.totalValue or active.totalValue
        SendNUIMessage({
            action = 'lootResult',
            payload = result
        })
    end
end

local function leaveInterior()
    local active = ZeeKotaClient.active
    if not active or active.stage ~= 'inside' then return end

    ZeeKotaClient.HideText()
    local result = ZeeKotaBridge.AwaitCallback('server:completeRobbery')
    if result and result.ok then
        ZeeKotaInteriors.Leave(active.house)
        ZeeKotaClient.Cleanup(false)
        SendNUIMessage({
            action = 'robberyComplete',
            payload = result.result
        })
    end
end

local function contactLoop()
    local coords = Config.ContactPed.coords
    if distanceTo(coords) <= Config.ContactPed.interaction.distance then
        ZeeKotaClient.ShowScreenPrompt(Config.ContactPed.interaction.text, Config.ContactPed.interaction.keyLabel)
        if IsControlJustPressed(0, Config.ContactPed.interaction.key or 38) then
            ZeeKotaClient.HideText()
            ZeeKotaUI.Open()
        end
        return true
    end

    return false
end

local function assignedLoop(active)
    local house = active.house
    local interaction = Config.DoorInteraction or {}
    if distanceTo(house.entrance) <= (interaction.distance or 2.0) then
        ZeeKotaClient.ShowScreenPrompt(interaction.text or 'Press E to Lock Pick Door', interaction.keyLabel)
        if IsControlJustPressed(0, interaction.key or 38) then
            tryDoorBreach()
        end
        return true
    end

    return false
end

local function insideLoop(active)
    local house = active.house

    if distanceTo(house.exit) <= 1.8 then
        ZeeKotaClient.ShowText(Config.Interiors.exitText)
        if IsControlJustReleased(0, 38) then
            leaveInterior()
        end
        return true
    end

    local nearestIndex
    local nearestZone
    local nearestDistance = 999.0

    for index, zone in ipairs(house.lootZones or {}) do
        if not active.searched[index] then
            local dist = distanceTo(zone.coords)
            if dist <= (zone.radius or 1.2) and dist < nearestDistance then
                nearestIndex = index
                nearestZone = zone
                nearestDistance = dist
            end
        end
    end

    if nearestZone then
        local interaction = Config.LootInteraction or {}
        local label = nearestZone.promptText or ('%s %s'):format(interaction.textPrefix or 'Press E to', nearestZone.label or 'Search')
        ZeeKotaClient.ShowScreenPrompt(label, interaction.keyLabel)
        if IsControlJustPressed(0, interaction.key or 38) then
            searchZone(nearestIndex, nearestZone)
        end
        return true
    end

    return false
end

CreateThread(function()
    ZeeKotaPeds.SpawnContact()

    while true do
        local sleep = 800
        local handled = false

        if ZeeKotaClient.active then
            sleep = 0
            if ZeeKotaClient.active.stage == 'assigned' then
                handled = assignedLoop(ZeeKotaClient.active)
            elseif ZeeKotaClient.active.stage == 'inside' then
                handled = insideLoop(ZeeKotaClient.active)
            end
        elseif Config.ContactPed.enabled then
            sleep = 250
            handled = contactLoop()
            if handled then
                sleep = 0
            end
        end

        if not handled then
            ZeeKotaClient.HideText()
        end

        Wait(sleep)
    end
end)

RegisterNetEvent(('%s:client:notify'):format(Config.ResourceName), function(data)
    ZeeKotaBridge.Notify(nil, data)
    SendNUIMessage({
        action = 'toast',
        message = data.description or data.message,
        type = data.type or 'inform',
        title = data.title
    })
end)

RegisterNetEvent(('%s:client:forceCleanup'):format(Config.ResourceName), function()
    ZeeKotaClient.Cleanup(true)
    SendNUIMessage({ action = 'robberyCancelled' })
end)

RegisterCommand(Config.Commands.cancel, function()
    local result = ZeeKotaBridge.AwaitCallback('server:cancelRobbery')
    if result and result.ok then
        ZeeKotaClient.Cleanup(true)
    end
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ZeeKotaClient.Cleanup(false)
end)
