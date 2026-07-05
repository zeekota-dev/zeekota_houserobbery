ZeeKotaUI = ZeeKotaUI or {}

local visible = false

local function requestDashboard()
    local result = ZeeKotaBridge.AwaitCallback('server:getDashboard')
    if not result or not result.ok then
        ZeeKotaBridge.Notify(nil, Config.Notifications.invalid)
        return nil
    end

    return result
end

function ZeeKotaUI.Open()
    local dashboard = requestDashboard()
    if not dashboard then return end

    visible = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openDashboard',
        payload = dashboard
    })
end

function ZeeKotaUI.Close()
    visible = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeDashboard' })
end

function ZeeKotaUI.IsOpen()
    return visible
end

RegisterNUICallback('close', function(_, cb)
    ZeeKotaUI.Close()
    cb({ ok = true })
end)

RegisterNUICallback('refreshDashboard', function(_, cb)
    cb(requestDashboard() or { ok = false })
end)

RegisterNUICallback('startRobbery', function(data, cb)
    local houseId = tonumber(data and data.houseId)
    local result = ZeeKotaBridge.AwaitCallback('server:startRobbery', houseId)

    if result and result.ok then
        ZeeKotaUI.Close()
        ZeeKotaClient.AssignRobbery(result.robbery)
    end

    cb(result or { ok = false })
end)

RegisterNUICallback('cancelRobbery', function(_, cb)
    local result = ZeeKotaBridge.AwaitCallback('server:cancelRobbery')

    if result and result.ok then
        ZeeKotaClient.Cleanup(true)
    end

    cb(result or { ok = false })
end)

RegisterNetEvent(('%s:client:openMenuFromItem'):format(Config.ResourceName), function()
    ZeeKotaUI.Open()
end)
