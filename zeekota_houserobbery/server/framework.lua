ZeeKotaFramework = ZeeKotaFramework or {}

function ZeeKotaFramework.Boot()
    CreateThread(function()
        for _ = 1, 30 do
            local name = ZeeKotaBridge.DetectFramework()
            if name then
                print(('[%s] Framework detected: %s'):format(Config.ResourceName, name))
                break
            end
            Wait(1000)
        end

        if Config.UsableMenuItem.enabled then
            local registered = ZeeKotaBridge.RegisterUsableItem(Config.UsableMenuItem.item, function(source)
                TriggerClientEvent(('%s:client:openMenuFromItem'):format(Config.ResourceName), source)
            end)

            if registered then
                print(('[%s] Usable item registered: %s'):format(Config.ResourceName, Config.UsableMenuItem.item))
            end
        end
    end)
end

ZeeKotaFramework.Boot()
