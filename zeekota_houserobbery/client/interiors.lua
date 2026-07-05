ZeeKotaInteriors = ZeeKotaInteriors or {}

local function toVector4(value)
    return vector4(value.x, value.y, value.z, value.w or value.heading or 0.0)
end

local function teleport(target)
    local ped = PlayerPedId()
    local coords = toVector4(target)

    DoScreenFadeOut(Config.Interiors.fadeMs)
    while not IsScreenFadedOut() do Wait(0) end

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w)
    Wait(150)

    DoScreenFadeIn(Config.Interiors.fadeMs)
end

CreateThread(function()
    for _, ipl in ipairs(Config.Interiors.requestIpls or {}) do
        RequestIpl(ipl)
    end
end)

function ZeeKotaInteriors.Enter(house)
    teleport(house.interiorSpawn)
end

function ZeeKotaInteriors.Leave(house)
    teleport(house.entrance)
end

function ZeeKotaInteriors.TeleportOutside(house)
    if house and house.entrance then
        teleport(house.entrance)
    end
end
