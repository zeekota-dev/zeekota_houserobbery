ZeeKotaMinigame = ZeeKotaMinigame or {}

local pending

RegisterNUICallback('minigameResult', function(data, cb)
    SetNuiFocus(false, false)

    if pending then
        pending:resolve(data and data.success == true)
        pending = nil
    end

    cb({ ok = true })
end)

function ZeeKotaMinigame.Start(tier)
    if pending then
        pending:resolve(false)
        pending = nil
    end

    local difficulty = Config.Lockpick.difficulties[tier] or Config.Lockpick.difficulties[1]
    pending = promise.new()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startMinigame',
        tier = tier,
        difficulty = difficulty
    })

    return Citizen.Await(pending)
end
