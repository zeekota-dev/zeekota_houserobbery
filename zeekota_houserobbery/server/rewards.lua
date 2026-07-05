ZeeKotaRewards = ZeeKotaRewards or {}

local function randomAmount(entry, multiplier)
    local min = math.floor((entry.min or 1) * multiplier)
    local max = math.floor((entry.max or min) * multiplier)
    if max < min then max = min end
    return math.random(min, max)
end

function ZeeKotaRewards.itemValue(item, amount)
    local value = Config.Rewards.itemValues[item] or 0
    return math.floor(value * (amount or 1))
end

local function giveReward(source, item, amount)
    if Config.Rewards.useFrameworkMoney and item == Config.Rewards.moneyItem then
        return ZeeKotaBridge.AddMoney(source, Config.Rewards.frameworkMoneyAccount, amount, 'zeekota_houserobbery')
    end

    return ZeeKotaBridge.AddItem(source, item, amount)
end

function ZeeKotaRewards.Roll(source, house, zone)
    local tier = house.tier or 1
    local multiplier = Config.Progression.lootMultiplierByTier[tier] or 1.0
    local rewards = {}
    local totalValue = 0

    for _, entry in ipairs(zone.loot or {}) do
        local chance = math.max(0, math.min(100, tonumber(entry.chance) or 0))
        if ZeeKotaBridge.RandomChance(chance) then
            local amount = randomAmount(entry, multiplier)
            local item = entry.item

            if giveReward(source, item, amount) then
                local value = ZeeKotaRewards.itemValue(item, amount)
                totalValue = totalValue + value
                rewards[#rewards + 1] = {
                    item = item,
                    amount = amount,
                    value = value
                }
            end
        end
    end

    return rewards, totalValue
end

function ZeeKotaRewards.CalculateXP(house, lootValue, alarmed)
    local tier = house.tier or 1
    local xp = Config.Progression.successXP
    xp = xp + (Config.Progression.tierXP[tier] or 0)
    xp = xp + math.floor((lootValue or 0) / math.max(1, Config.Progression.lootXPValueDivisor))

    if alarmed then
        xp = xp + (Config.Progression.alarmPenaltyXP or 0)
    else
        xp = xp + (Config.Progression.stealthBonusXP or 0)
    end

    return math.max(0, xp)
end
