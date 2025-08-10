local RSGCore = exports['rsg-core']:GetCoreObject()
local buyerPed = nil
local started = false
local hasDropOff = false
local madeDeal = nil
local dropOffArea = nil
local spawnlocation = nil
lib.locale()

-----------------------------------
-- create dropoff blip
-----------------------------------
local CreateDropOffBlip = function(coords)
    dropOffBlip = BlipAddForCoords(1664425300, coords)
    SetBlipSprite(dropOffBlip, `blip_ambient_npc`)
    SetBlipScale(dropOffBlip, 1.0)
    SetBlipName(dropOffBlip, 'Dropoff')
    BlipAddModifier(dropOffBlip, joaat('BLIP_MODIFIER_MP_COLOR_29'))
end

-----------------------------------
-- create the dropoff
-----------------------------------
local CreateDropOff = function(item, amount, spawn)

    hasDropOff = true

    lib.notify({ 
        title = locale('cl_lang_1'),
        description = locale('cl_lang_2'),
        type = 'inform',
        position = 'center-right',
        duration = 5000 
    })
    local randomLoc = nil
    if spawn == 'valentine' then
        randomLoc = Config.ValentineLocations[math.random(#Config.ValentineLocations)]
    elseif spawn == 'stdenis' then
        randomLoc = Config.StDenisLocations[math.random(#Config.StDenisLocations)]
    else
        lib.notify({ 
            title = locale('cl_lang_3'),
            type = 'inform',
            position = 'center-right',
            duration = 7000 
        })
    end
    
    -- create dropoff blips
    CreateDropOffBlip(randomLoc.coords)
    
    -- create polyzone
    dropOffArea = CircleZone:Create(randomLoc.coords, 10.0, {
        name = "dropOffArea",
        debugPoly = false
    })
    
    -- spawn buyer ped when in polyzone
    dropOffArea:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            if buyerPed == nil then
            
                lib.notify({
                    title = locale('cl_lang_4'),
                    type = 'inform',
                    position = 'center-right',
                    duration = 5000
                })
                
                local pedModel = Config.PedModels[math.random(#Config.PedModels)]

                RequestModel(pedModel)
                
                while not HasModelLoaded(pedModel) do
                    Wait(100)
                end

                buyerPed = CreatePed(pedModel, randomLoc.coords, randomLoc.heading, true, true)
                SetEntityInvincible(buyerPed, true)
                SetBlockingOfNonTemporaryEvents(buyerPed, true)
                SetRandomOutfitVariation(buyerPed, true)
                PlaceEntityOnGroundProperly(buyerPed, true)
                Wait(1000)
                FreezeEntityPosition(buyerPed, true)
                exports.ox_target:addLocalEntity(buyerPed, {
                    {
                        name = 'npcsellweed',
                        icon = 'fa-solid fa-cannabis',
                        label = locale('cl_lang_5'),
                        onSelect = function()
                            TriggerEvent('rex-contraband:client:dealer:delivery', item, amount)
                        end,
                        distance = 2.0
                    }
                })
            end
        end
    end)
end

-----------------------------------
-- delete buyer ped
-----------------------------------
local DeleteBuyerPed = function()
    if buyerPed == nil then return end
    FreezeEntityPosition(buyerPed, false)
    SetPedKeepTask(buyerPed, false)
    TaskSetBlockingOfNonTemporaryEvents(buyerPed, false)
    ClearPedTasks(buyerPed)
    TaskWanderStandard(buyerPed, 10.0, 10)
    SetPedAsNoLongerNeeded(buyerPed)
    Wait(20000)
    DeletePed(buyerPed)
    buyerPed = nil
end

-----------------------------------
-- start the contraband run
-----------------------------------
local StartSelling = function(item, amount, spawn)
    if started then return end
    started = true
    lib.notify({
        title = locale('cl_lang_6'),
        description = locale('cl_lang_7'),
        type = 'inform',
        position = 'center-right',
        duration = 5000
    })
    while started do
        Wait(4000)
        if not hasDropOff then
            Wait(8000)
            CreateDropOff(item, amount, spawn  )
        end
    end
end

local DoWeedSell = function()
    local player = PlayerPedId()
    local animScene = CreateAnimScene('script@beat@town@townRobbery@handover_money', 64, 0, 0, 1)
    local pCoord = GetEntityCoords(player, 1, 0)
    pCoord = GetOffsetFromEntityInWorldCoords(player, -0.0497, 1.2016, 0.0)
    local pRot = GetEntityRotation(player, 2)
    SetAnimSceneOrigin(animScene, pCoord.x, pCoord.y, pCoord.z, pRot.x, pRot.y, pRot.z - 175.66, 2)
    SetAnimSceneEntity(animScene, "pedPlayer", player, 0)
    local objectModel = GetHashKey('s_herbalpouch01x')
    local objPouch = CreateObject(objectModel, pCoord.x, pCoord.y, pCoord.z, 2)
    SetAnimSceneEntity(animScene, "objPouch", objPouch, 0)
    SetEntityVisible(objPouch, false)
    local boneIndex = GetPedBoneIndex(player, 7966)
    AttachEntityToEntity(objPouch, player, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1, 0, 0)
    -- SetAnimSceneEntity(animScene, "pedStranger", 24625, 0)
    LoadAnimScene(animScene)
    Citizen.Wait(1000)
    StartAnimScene(animScene)
    Citizen.Wait(500)
    SetEntityVisible(objPouch, true)
    Citizen.Wait(2500)
    SetEntityAsMissionEntity(objPouch, true, true)
    DeleteObject(objPouch)
    Citizen.Wait(3000)
    Citizen.InvokeNative(0x84EEDB2C6E650000 , animScene)
end

-----------------------------------
-- start selling
-----------------------------------
RegisterNetEvent('rex-contraband:client:dealer:startselling', function(item, amount)
    RSGCore.Functions.TriggerCallback('rsg-lawman:server:getlaw', function(result)
        -- check how many lawman are on duty before starting the run
        if result < Config.LawmanOnDuty then
            lib.notify({
                title = locale('cl_lang_8'),
                description = locale('cl_lang_9'),
                type = 'error',
                icon = 'fa-solid fa-handcuffs',
                iconAnimation = 'shake',
                duration = 7000
            })
            return
        end

        local x,y,z =  table.unpack(GetEntityCoords(cache.ped))
        local town_hash = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, 1)
        
        if town_hash == false then
            lib.notify({
                title = locale('cl_lang_10'),
                description = locale('cl_lang_11'),
                type = 'error',
                icon = 'fa-solid fa-handcuffs',
                iconAnimation = 'shake',
                duration = 7000
            })
            return
        end

        if town_hash == 459833523 then
            spawnlocation = 'valentine'
        end

        if town_hash == -765540529 then
            spawnlocation = 'stdenis'
        end

        local hasItem = RSGCore.Functions.HasItem(item, amount)

        if not hasItem then
            lib.notify({
                title = locale('cl_lang_12'),
                description = locale('cl_lang_13'),
                type = 'error',
                icon = 'fa-solid fa-circle-exclamation',
                iconAnimation = 'shake',
                duration = 7000
            })
            spawnlocation = nil
            return
        end

        -- if player has cash / contraband and law on duty meets config start run
        if started then return end
        if spawnlocation == nil then return end
        StartSelling(item, amount, spawnlocation)
    end)
end)

-----------------------------------
-- deliver contraband
-----------------------------------
RegisterNetEvent('rex-contraband:client:dealer:delivery', function(item, amount)
    if madeDeal then return end
    if not IsPedOnFoot(cache.ped) then return end
    if #(GetEntityCoords(cache.ped) - GetEntityCoords(buyerPed)) < 5.0 then

        madeDeal = true
        
        local hasItem = RSGCore.Functions.HasItem(item, amount)

        if not hasItem then
            lib.notify({
                title = locale('cl_lang_14'),
                description = locale('cl_lang_15'),
                type = 'inform',
                position = 'center-right',
                duration = 5000
            })
            started = false
            madeDeal = false
        else
            if math.random(100) <= Config.CallLawChance then
                TriggerServerEvent('rsg-lawman:server:lawmanAlert', locale('cl_lang_18'))
            end
			DoWeedSell()
            TriggerServerEvent('rex-contraband:server:dealer:dotrade', item, amount)
            lib.notify({
                title = locale('cl_lang_16'),
                description = locale('cl_lang_17'),
                type = 'inform',
                position = 'center-right',
                duration = 5000
            })
            TriggerServerEvent('rex-contraband:server:dealer:updateoutlawstatus')
            exports['rsg-target']:RemoveTargetEntity(buyerPed)
            RemoveBlip(dropOffBlip)
            dropOffArea:destroy()
            dropOffBlip = nil
            DeleteBuyerPed()
            hasDropOff = false
            madeDeal = false
        end
    end
end)
