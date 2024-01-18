local QBCore = exports['qb-core']:GetCoreObject()
local SellPed = nil
local Barrels = {}
local CanBottle = false

local function findKeyPosition(myTable, key)
    for i, value in ipairs(myTable) do
        if value == key then
            return i
        end
    end
    return nil  -- Key not found
end

local function isTableEmpty(tbl)
    return next(tbl) == nil
end

-----------------------------
-- MASH
-----------------------------

RegisterNetEvent('kg-moonshing:PlaceBarrel', function()
    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.5, 0.0)
    local pedpos = GetEntityCoords(ped)

    local model = `prop_barrel_02a`
    RequestModel(model)
    while not HasModelLoaded(model) do
      Wait(1)
    end

    TriggerEvent('animations:client:EmoteCommandStart', {"mechanic"})
    QBCore.Functions.Progressbar("search_register", "Seting Up Barrel...", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        Wait(500)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify("Cancelled", "error", 3500)
        ClearPedTasks(ped)
        Wait(500)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end)

    Wait(6000)

    local barrel = CreateObject(model, pos, true, true, false)

    PlaceObjectOnGroundProperly(barrel)

    FreezeEntityPosition(barrel, true)

    local entity = GetClosestObjectOfType(pedpos, 1.0, model, false, false, false)

    Barrels[entity] = {
        ['isFilled'] = false,
        ['isReady'] = false,
        ['timeRemain'] = 3000000,
    }

    exports['qb-target']:AddTargetEntity(barrel, {
        options = {
          {
            type = "client",
            event = "kg-moonshing:AddIngredients",
            label = 'Mix Ingredients',
            args = {
                entity = barrel,
            },
          },
          {
            type = "client",
            label = 'Pickup Barrel',
            action = function(entity)
                if IsPedAPlayer(entity) then return end 
                TriggerServerEvent('kg-moonshing:PickupEmptyBarrel', NetworkGetNetworkIdFromEntity(entity))
                TriggerEvent('kg-moonshine:RemoveBarrelTarget', entity)
            end,
            args = {
                entity = barrel,
            },
          },
        },
        distance = 1.5,
    })

    TriggerServerEvent('kg-moonshine:TakeBarrel')
end)

RegisterNetEvent('kg-moonshing:AddIngredients', function(data)

    local entity = data.entity

    if not QBCore.Functions.HasItem('corn_bag') then
        QBCore.Functions.Notify('You Have No Corn', 'error')
        return
    end

    if not QBCore.Functions.HasItem('water_bottle') then
        QBCore.Functions.Notify('You Have No Water Bottles', 'error')
        return
    end

    if not QBCore.Functions.HasItem('sugar_bag') then
        QBCore.Functions.Notify('You Have No Sugar', 'error')
        return
    end

    if not QBCore.Functions.HasItem('yeast') then
        QBCore.Functions.Notify('You Have No Yeast', 'error')
        return
    end

    Barrels[entity] = {
        ['isFilled'] = true,
        ['isReady'] = false,
        ['timeRemain'] = Config.FermentTime,
    }

    exports['qb-target']:RemoveTargetEntity(entity)

    exports['qb-target']:AddTargetEntity(entity, {
        options = {
          {
            type = "client",
            event = "kg-moonshing:CheckTime",
            label = 'Check Remaining Time',
          }
        },
        distance = 1.5,
    })

    TriggerEvent('animations:client:EmoteCommandStart', {"mechanic"})
    QBCore.Functions.Progressbar("search_register", "Adding Ingredients...", 60000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        local ped = PlayerPedId()

        TriggerServerEvent('kg-moonshine:TakeIngredients')

        ClearPedTasks(ped)
        Wait(500)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify("Cancelled", "error", 3500)
        ClearPedTasks(ped)
        Wait(500)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end)
end)

RegisterNetEvent('kg-moonshing:CheckTime', function()
    local ped = PlayerPedId()
    local pedpos = GetEntityCoords(ped)
    local entity = GetClosestObjectOfType(pedpos, 1.0, GetHashKey("prop_barrel_02a"), false, false, false)
    local PlayerData = QBCore.Functions.GetPlayerData()

    if Barrels[entity] ~= nil then
        local rem = (Barrels[entity].timeRemain / (1000 * 60))
        if rem ~= 0 then
            QBCore.Functions.Notify('Minute\'s Remaining: ' .. rem, 'error')
        else
            QBCore.Functions.Notify('Barrel Is Ready', 'success')
            exports['qb-target']:RemoveTargetEntity(entity)

            exports['qb-target']:AddTargetEntity(entity, {
                options = {
                    {
                        type = "client",
                        --event = "kg-moonshing:client:TakeMash",
                        label = 'Take Mash',
                        action = function(entity)
                            if IsPedAPlayer(entity) then return end 
                            TriggerServerEvent('kg-moonshing:TakeMash', NetworkGetNetworkIdFromEntity(entity))
                            TriggerEvent('kg-moonshine:RemoveBarrelTarget', entity)
                        end,
                    },

                    {
                        num = 2,
                        type = "client",
                        --event = "kg-moonshing:client:TakeMash",
                        label = 'Destroy Mash',
                        action = function(entity)
                            if IsPedAPlayer(entity) then return end 
                            TriggerServerEvent('kg-moonshing:DestroyMash', NetworkGetNetworkIdFromEntity(entity))
                            TriggerEvent('kg-moonshine:RemoveBarrelTarget', entity)
                        end,
                        job = "police",
                    },
                },
                distance = 1.5,
            })
        end
    end
end)

RegisterNetEvent('kg-moonshine:RemoveBarrelTarget', function(entity)
    exports['qb-target']:RemoveTargetEntity(entity)
    Barrels[entity] = nil

    local remove = findKeyPosition(Barrels, Barrels[entity])
    table.remove(Barrels, remove)
end)


-----------------------------
-- STILL
-----------------------------


RegisterNetEvent('kg-moonshine:UseStill', function()

    if not QBCore.Functions.HasItem('mash') then
        QBCore.Functions.Notify('You Have No Mash', 'error')
        return
    end

    TriggerEvent('animations:client:EmoteCommandStart', {"mechanic"})
    QBCore.Functions.Progressbar("search_register", "Adding Mash...", 60000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        local ped = PlayerPedId()

        TriggerServerEvent('kg-moonshine:still:TakeMash')
        TriggerEvent('kg-moonshine:UseStill:Stage2')

        ClearPedTasks(ped)
        Wait(500)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify("You Poured It All On The Ground Idiot", "error")
        ClearPedTasks(ped)
        Wait(500)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end)
end)

RegisterNetEvent('kg-moonshine:UseStill:Stage2', function()
    QBCore.Functions.Progressbar("search_register", "Watching Mash...", 60000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        QBCore.Functions.Notify("Liquor Ready In Bucket For Jaring", "success")
        CanBottle = true
    end, function() -- Cancel
        QBCore.Functions.Notify("Still Boiled Over And You Burnt Your Batch", "error")
    end)
end)

RegisterNetEvent('kg-moonshine:TakeMoonshine', function()

    if CanBottle == false then return end

    TriggerEvent('animations:client:EmoteCommandStart', {"medic2"})
    QBCore.Functions.Progressbar("search_register", "Bottling...", 60000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(PlayerPedId())
        TriggerServerEvent('kg-moonshine:still:Reward', GetEntityCoords(PlayerPedId()))
        TriggerServerEvent('kg-skills:UpdateSkill', 'shining')
        CanBottle = false
        Wait(500)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify("You Knocked Over The Bucket And All That Hard Work Gone", "error")
        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'breaking_vitrine_glass', 0.25)
        CanBottle = false
        Wait(500)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end)
end)

-----------------------------
-- Selling
-----------------------------

RegisterNetEvent('kg-moonshine:Menu', function()
    local menu = {
        [1] = {
            isMenuHeader = true,
            header = 'Party Goer:',
        },
    }

    if QBCore.Functions.HasItem('moonshine') then
        menu[#menu + 1 ] = {
            header = 'Sell Moonshine',
            params = {
                isServer = true,
                event = 'kg-moonshine:Sell',
            }
        }
    end

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('kg-moonshine:CallPolice', function()
    exports['ps-dispatch']:SuspiciousActivity()
end)

-----------------------------
-- Startup & Cleanup
-----------------------------

Citizen.CreateThread(function()
    exports['qb-target']:AddBoxZone("still_zone", vector3(-33.13, 3035.24, 41.03), 1, 1, {
        name = "still_zone",
        heading = 15.0,
        debugPoly = false,
        minZ = 37.83,
        maxZ = 41.83,
    }, {
        options = {
            {
                type = "client",
                event = "kg-moonshine:UseStill",
                label = "Use Still",
            },
        },
        distance = 2.5
    })

    exports['qb-target']:AddBoxZone("still_take_zone", vector3(-32.69, 3033.26, 41.1), 1, 1, {
        name = "still_take_zone",
        heading = 10.0,
        debugPoly = false,
        minZ = 37.3,
        maxZ = 41.3,
    }, {
        options = {
            {
                type = "client",
                event = "kg-moonshine:TakeMoonshine",
                label = "Take MoonShine",
            },
        },
        distance = 2.5
    })

    local model = `a_f_m_beach_01`
    RequestModel(model)
    while not HasModelLoaded(model) do
      Wait(1)
    end
    SellPed = CreatePed(0, model, Config.SellLocation, true, false)
    SetEntityInvincible(SellPed, true)
    SetBlockingOfNonTemporaryEvents(SellPed, true)
    Citizen.Wait(1350)
    TaskStartScenarioInPlace(SellPed, "WORLD_HUMAN_PARTYING", 0, true)
    FreezeEntityPosition(SellPed, true)

    exports['qb-target']:AddTargetEntity(SellPed, {
      options = {
        {
          type = "client",
          event = "kg-moonshine:Menu",
          label = 'Talk To Party Goer',
        }
      },
      distance = 2.5,
    })
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 2000

        if not isTableEmpty(Barrels) then
            for key, value in pairs(Barrels) do
                if Barrels[key].timeRemain > 0 then
                    Barrels[key].timeRemain = (Barrels[key].timeRemain - 2000)
                else
                    Barrels[key].isReady = true
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
  
    exports['qb-target']:RemoveZone("still_zone")
    exports['qb-target']:RemoveZone("still_take_zone")
    exports['qb-target']:RemoveTargetEntity(SellPed)
    DeleteEntity(SellPed)
end)