local QBCore = exports['qb-core']:GetCoreObject()
local Mash = {}

local function exploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            GetPlayerName(id),
            QBCore.Functions.GetIdentifier(id, 'license'),
            QBCore.Functions.GetIdentifier(id, 'discord'),
            QBCore.Functions.GetIdentifier(id, 'ip'),
            reason,
            2147483647,
            'kg-moonshine'
        })
    TriggerEvent('qb-log:server:CreateLog', 'Moonshine', 'Player Banned', 'red',
        string.format('%s was banned by %s for %s', GetPlayerName(id), 'kg-moonshine', reason), true)
    DropPlayer(id, 'You were permanently banned by the server for: Exploiting')
end

-----------------------------
-- MASH
-----------------------------

RegisterServerEvent('kg-moonshine:TakeBarrel', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    Player.Functions.RemoveItem('mash_barrel', 1)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['mash_barrel'], "remove", 1)
end)

RegisterServerEvent('kg-moonshine:TakeIngredients', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveItem('corn_bag', 15) then
        TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['corn_bag'], "remove", 15)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You Have Not Enough Corn', 'error')
        return
    end

    if Player.Functions.RemoveItem('water_bottle', 20) then
        TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['water_bottle'], "remove", 20)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You Have Not Enough Water Bottles', 'error')
        Player.Functions.AddItem('corn_bag', 15)
        return
    end

    if Player.Functions.RemoveItem('sugar_bag', 15) then
        TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['sugar_bag'], "remove", 15)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You Have Not Enough Sugar', 'error')
        Player.Functions.AddItem('corn_bag', 15)
        Player.Functions.AddItem('water_bottle', 20)
        return
    end

    if Player.Functions.RemoveItem('yeast', 1) then
        TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['yeast'], "remove", 1)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You Have Not Enough Yeast', 'error')
        Player.Functions.AddItem('corn_bag', 15)
        Player.Functions.AddItem('sugar_bag', 15)
        Player.Functions.AddItem('water_bottle', 20)
        return
    end
end)

RegisterServerEvent('kg-moonshing:TakeMash', function(entityid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local entity = NetworkGetEntityFromNetworkId(entityid)
    DeleteEntity(entity)

    Player.Functions.AddItem('mash', 1)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['mash'], "add", 1)
    Player.Functions.AddItem('mash_barrel', 1)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['mash_barrel'], "add", 1)
end)

-----------------------------
-- STILL
-----------------------------

RegisterServerEvent('kg-moonshine:still:TakeMash', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local item = Player.Functions.GetItemByName('mash')
    local amount = 0

    if item.amount ~= nil then
        amount = item.amount
    end

    Mash[tonumber(src)] = amount

    Player.Functions.RemoveItem('mash', amount)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['mash'], "remove", amount)
end)

RegisterServerEvent('kg-moonshine:still:Reward', function(pos)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if pos.x + 10 < -33.13 or pos.x - 10 > -33.13 then
        exploitBan(source, "Outside Permitted Reward Zone")
    end

    local amount = (Mash[tonumber(src)] * 100)

    Player.Functions.AddItem('moonshine', amount)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['moonshine'], "add", amount)

    Mash[tonumber(src)] = 0

end)

-----------------------------
-- Selling
-----------------------------

RegisterServerEvent('kg-moonshine:Sell', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local item = Player.Functions.GetItemByName('moonshine')

    if item.amount == nil or item == nil then
        item.amount = 0
        return
    end

    local retamount = (item.amount * Config.SellPrice)

    Player.Functions.RemoveItem('moonshine', item.amount)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['moonshine'], "remove", item.amount)
    Player.Functions.AddMoney('cash', retamount)

    local callChance = math.random(1, 100)

    if callChance <= Config.CallChance then
        TriggerClientEvent('kg-moonshine:CallPolice', src)
    end
end)

-----------------------------
-- Other
-----------------------------

RegisterServerEvent('kg-moonshing:DestroyMash', function(entityid)
    local entity = NetworkGetEntityFromNetworkId(entityid)
    DeleteEntity(entity)
end)

RegisterServerEvent('kg-moonshing:PickupEmptyBarrel', function(entityid)
    local entity = NetworkGetEntityFromNetworkId(entityid)
    local src = source
    DeleteEntity(entity)
    local Player = QBCore.Functions.GetPlayer(src)

    Player.Functions.AddItem('mash_barrel', 1)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items['mash_barrel'], "add", 1)
end)

QBCore.Functions.CreateUseableItem("mash_barrel", function(source, item)
    TriggerClientEvent('kg-moonshing:PlaceBarrel', source)
end)