local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

-------------------------------
-- command start selling
-------------------------------
RSGCore.Commands.Add('sellweed', locale('sv_lang_1'), {}, true, function(source, args)
    local src = source
    TriggerClientEvent('rex-contraband:client:dealer:startselling', src, 'weed', 1)
end)

-------------------------------
-- do trade
-------------------------------
RegisterNetEvent('rex-contraband:server:dealer:dotrade', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney(Config.RewardMoney, Config.TradePrice * Config.TradeAmount)
    Player.Functions.RemoveItem(Config.TradeItem, Config.TradeAmount)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.TradeItem], 'remove', Config.MoonshineTradeAmount)
end)

---------------------------------
-- get and update players outlawstatus
---------------------------------
RegisterNetEvent('rex-contraband:server:dealer:updateoutlawstatus', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    MySQL.query('SELECT outlawstatus FROM players WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(result)
        if result[1] then
            local outlawadd = math.random(Config.MinOutlawAdd,Config.MaxOutlawAdd)
            local statusupdate = result[1].outlawstatus + outlawadd
            MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { statusupdate, Player.PlayerData.citizenid })
        else
            print(locale('sv_lang_2'))
        end
    end)
end)
