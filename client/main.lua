
QBCore = exports['qb-core']:GetCoreObject()


----QBShared.Items = exports["qb-core"]:GetShared("Items")
--QBShared.SplitStr = exports["qb-core"]:GetShared("SplitStr")
inInventory = false
hotbarOpen = false
local inUse = false
local inventoryTest = {}
local currentWeapon = nil
local CurrentWeaponData = {}
local currentOtherInventory = nil
local Drops = {}
local CurrentDrop = 0
local DropsNear = {}
local CurrentVehicle = nil
local CurrentGlovebox = nil
local CurrentStash = nil
local isCrafting = false
local isHotbar = false
local showTrunkPos = false
local statusInventory = false
local status = true
local InCrafting = false
local inventoryData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    LocalPlayer.state:set("inv_busy", false, true)
end)

RegisterNetEvent('inventory:client:statusInventory')
AddEventHandler('inventory:client:statusInventory', function(bool)
  statusInventory = bool
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload")
AddEventHandler("QBCore:Client:OnPlayerUnload", function()
    LocalPlayer.state:set("inv_busy", true, true)
end)

RegisterNetEvent('inventory:client:CheckOpenState')
AddEventHandler('inventory:client:CheckOpenState', function(type, id, label)
    local name = QBShared.SplitStr(label, "-")[2]
    if type == "stash" then
        if (name ~= CurrentStash and id ~= CurrentStash) or CurrentStash == nil then
            TriggerServerEvent('inventory:server:SetIsOpenState', false, type, id)
        end
    elseif type == "trunk" then
        if (name ~= CurrentVehicle and id ~= CurrentVehicle) or CurrentVehicle == nil then
            TriggerServerEvent('inventory:server:SetIsOpenState', false, type, id)
        end
    elseif type == "glovebox" then
        if (name ~= CurrentGlovebox and id ~= CurrentGlovebox) or CurrentGlovebox == nil then
            TriggerServerEvent('inventory:server:SetIsOpenState', false, type, id)
        end
    end
end)

RegisterNetEvent('weapons:client:SetCurrentWeapon')
AddEventHandler('weapons:client:SetCurrentWeapon', function(data, bool)
    if data then
        CurrentWeaponData = data
    else
        CurrentWeaponData = {}
    end
end)

function GetClosestVending()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local object = nil
    for _, machine in pairs(Config.VendingObjects) do
        local ClosestObject = GetClosestObjectOfType(pos.x, pos.y, pos.z, 0.75, GetHashKey(machine), 0, 0, 0)
        if ClosestObject ~= 0 and ClosestObject ~= nil then
            if object == nil then
                object = ClosestObject
            end
        end
    end
    return object
end

function DrawText3Ds(x, y, z, text)
	QBCore.Functions.HelpNotify(text)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(7)
        if showTrunkPos and not inInventory then
            local vehicle = QBCore.Functions.GetClosestVehicle()
            if vehicle ~= 0 and vehicle ~= nil then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local vehpos = GetEntityCoords(vehicle)
                if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(ped) then
                    local drawpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
                    if (IsBackEngine(GetEntityModel(vehicle))) then
                        drawpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, 2.5, 0)
                    end
                    QBCore.Functions.DrawText3D(drawpos.x, drawpos.y, drawpos.z, "Almacen")
                    if #(pos - drawpos) < 2.0 and not IsPedInAnyVehicle(ped) then
                        CurrentVehicle = GetVehicleNumberPlateText(vehicle)
                        showTrunkPos = false
                    end
                else
                    showTrunkPos = false
                end
            else
                Citizen.Wait(500)
            end
        else
            Citizen.Wait(500)
        end
    end
end)


Citizen.CreateThread(function()
    while true do
       
        local sleepTime = 100
        if inInventory then
            sleepTime = 1
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 287, true)
            DisableControlAction(0, 286, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 80, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 26, true)
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 70, true)
            DisableControlAction(0, 91, true)
            DisableControlAction(0, 92, true)
               
            local player = PlayerInFront()
            if player ~= 0 and IsPedAPlayer(player) then
                local coords = GetEntityCoords(player)
                if #(GetEntityCoords(PlayerPedId()) - coords) < Config.GiveDistance then
                    DrawMarker(20, coords+vector3(0, 0, 1.1), 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.1, 0.1, 0.1, 0, 0, 0, 255, 1, 0, 0, 1)
                end
            end
        end
        Citizen.Wait(sleepTime)
    end
end)

function isInInventory()
    return inInventory
end

exports('isInInventory', isInInventory)

RegisterNetEvent("qb-inventory:closeInv")
AddEventHandler("qb-inventory:closeInv", function()
    SendNUIMessage({
        action = "close"
    })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    if InCrafting then
        ClearPedTasks(PlayerPedId())
        InCrafting = false
    end
    inInventory = false
    --QBCore.Functions.SetNuiFocused(false)
end)

-- Inventory Main Thread
RegisterCommand('inventory2', function()
    if inInventory then
        SendNUIMessage({
            action = "close"
        })
        return
    elseif IsNuiFocused() then
        return
    end
    -- local phoneOpen = exports['qb-phone']:InPhone()
    if not phoneOpen then
        if not isCrafting and statusInventory == false then
            if status == true then
                QBCore.Functions.GetPlayerData(function(PlayerData)
                    if not PlayerData.metadata["isdead"] and not PlayerData.metadata["inlaststand"] and not PlayerData.metadata["ishandcuffed"] and not IsPauseMenuActive() then
                        local ped = PlayerPedId()
                        local curVeh = nil
                        --local VendingMachine = GetClosestVending()

                        -- Is Player In Vehicle

                        if IsPedInAnyVehicle(ped) and GetEntityModel(GetVehiclePedIsIn(ped, false)) ~= -1963629913 then
                            local vehicle = GetVehiclePedIsIn(ped, false)
                            CurrentGlovebox = GetVehicleNumberPlateText(vehicle)
                            curVeh = vehicle
                            CurrentVehicle = nil
                        else
                            local vehicle = QBCore.Functions.GetClosestVehicle()
                            if vehicle ~= 0 and vehicle ~= nil and GetEntityModel(vehicle) ~= -1963629913 then
                                local pos = GetEntityCoords(ped)
                                local trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
                                if (IsBackEngine(GetEntityModel(vehicle))) then
                                    trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, 2.5, 0)
                                end
                                if #(pos - trunkpos) < 2.0 and not IsPedInAnyVehicle(ped) then
                                    if GetVehicleDoorLockStatus(vehicle) == 0 then
                                        CurrentVehicle = GetVehicleNumberPlateText(vehicle)
                                        curVeh = vehicle
                                        CurrentGlovebox = nil
                                    else
                                        QBCore.Functions.Notify("El vehículo está bloqueado...", "error")
                                        return
                                    end
                                else
                                    CurrentVehicle = nil
                                end
                            else
                                CurrentVehicle = nil
                            end
                        end

                        -- Trunk
            
                        if CurrentVehicle ~= nil then
                            local cP, cD = QBCore.Functions.GetClosestPlayer()
                            if cD ~= -1 and cD < 1.5 then
                                QBCore.Functions.Notify("Ya hay alguien usando este maletero o tienes alguien demasiado cerca!")
                                return
                            end
                            if cP ~= -1 and cD ~= -1 and cD < 1.5 and ((not IsBackEngine(GetEntityModel(curVeh)) and GetVehicleDoorAngleRatio(curVeh, 5) > 0.0) or (IsBackEngine(GetEntityModel(curVeh)) and GetVehicleDoorAngleRatio(curVeh, 4) > 0.0 )) then
                                QBCore.Functions.Notify("Ya hay alguien usando este maletero o tienes alguien demasiado cerca!")
                                return
                            end

                            local maxweight = 0
                            local slots = 0
                            if GetVehicleClass(curVeh) == 0 then
                                maxweight = 38000
                                slots = 30
                            elseif GetVehicleClass(curVeh) == 1 then
                                maxweight = 50000
                                slots = 40
                            elseif GetVehicleClass(curVeh) == 2 then
                                maxweight = 75000
                                slots = 50
                            elseif GetVehicleClass(curVeh) == 3 then
                                maxweight = 42000
                                slots = 35
                            elseif GetVehicleClass(curVeh) == 4 then
                                maxweight = 38000
                                slots = 30
                            elseif GetVehicleClass(curVeh) == 5 then
                                maxweight = 30000
                                slots = 25
                            elseif GetVehicleClass(curVeh) == 6 then
                                maxweight = 30000
                                slots = 25
                            elseif GetVehicleClass(curVeh) == 7 then
                                maxweight = 30000
                                slots = 25
                            elseif GetVehicleClass(curVeh) == 8 then
                                maxweight = 15000
                                slots = 15
                            elseif GetVehicleClass(curVeh) == 9 then
                                maxweight = 60000
                                slots = 35
                            elseif GetVehicleClass(curVeh) == 12 then
                                maxweight = 120000
                                slots = 35
                            else
                                maxweight = 60000
                                slots = 35
                            end
                            local other = {
                                maxweight = maxweight,
                                slots = slots,
                            }
                            QBCore.Functions.Progressbar("eat_something", "Abriendo maletero...", 3000, false, true, {
                                disableMovement = false,
                                disableCarMovement = false,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = "anim@gangops@facility@servers@bodysearch@",
                                anim = "player_search",
                                flags = 49,
                            }, {}, {}, function() -- Done
                                StopAnimTask(PlayerPedId(), "anim@gangops@facility@servers@bodysearch@", "player_search", 1.0)
                                TriggerServerEvent("inventory:server:OpenInventory", "trunk", CurrentVehicle, other)
                                OpenTrunk()
                                ExecuteCommand("me abre el maletero")
                            end)
                            
                        elseif CurrentGlovebox ~= nil then
                            TriggerServerEvent("inventory:server:OpenInventory", "glovebox", CurrentGlovebox)
                        elseif CurrentDrop ~= 0 then
                            TriggerServerEvent("inventory:server:OpenInventory", "drop", CurrentDrop)
                        elseif VendingMachine ~= nil then
                            local ShopItems = {}
                            ShopItems.label = "Vending Machine"
                            ShopItems.items = Config.VendingItem
                            ShopItems.slots = #Config.VendingItem
                            TriggerServerEvent("inventory:server:OpenInventory", "shop", "Vendingshop_"..math.random(1, 99), ShopItems)
                        else
                            TriggerServerEvent("inventory:server:OpenInventory")
                        end
                    end    
                end)
            end
        end
    end
end)

RegisterKeyMapping('inventory2', 'Abrir Inventario', 'keyboard', 'F2')

RegisterNetEvent('inventory:hideHotBar')
AddEventHandler('inventory:hideHotBar', function()
    SendNUIMessage({
        action = "toggleHotbar",
        open = false
    })
end)

RegisterCommand('hotbar', function()
    local status = exports['progressbar']:checkStatus()
    local isDead = exports['qb-hud']:checkIsDeathI()
    if status == false and isDead == false then
        isHotbar = not isHotbar
        ToggleHotbar(isHotbar)
    end
end)

for i=1, 5 do 
    RegisterCommand('slot' .. i,function()
        if IsNuiFocused() then return end
        if inInventory then return end
        QBCore.Functions.GetPlayerData(function(PlayerData)
            -- local phoneOpen = exports['qb-phone']:InPhone()
            if not PlayerData.metadata["isdead"] and not PlayerData.metadata["inlaststand"] and not PlayerData.metadata["ishandcuffed"] and not IsPauseMenuActive() and inUse == false --[[and phoneOpen == false]] then
                if i == 6 then 
                    i = 41
                end
                inUse = true
                TriggerServerEvent("inventory:server:UseItemSlot", i)
                SendNUIMessage({
                    action = "ocultarHotbar"
                   
                })
                Citizen.Wait(1500)
                inUse = false
            end
        end)
    end)
    RegisterKeyMapping('slot' .. i, 'Usar el item del slot ' .. i, 'keyboard', i)
end

RegisterNetEvent('inventory:client:ItemBox')
AddEventHandler('inventory:client:ItemBox', function(itemData, type)
    SendNUIMessage({
        action = "itemBox",
        item = itemData,
        type = type
    })
end)

RegisterNetEvent('inventory:client:requiredItems')
AddEventHandler('inventory:client:requiredItems', function(items, bool)
    local itemTable = {}

    
    SendNUIMessage({
        action = "requiredItem",
        items = itemTable,
        toggle = bool
    })
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1200
        if DropsNear ~= nil then
            local pos = GetEntityCoords(PlayerPedId(), true)
            for k, v in pairs(DropsNear) do
                if DropsNear[k] ~= nil then
                    local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                    if dist < 10 then
                        sleep = 300
                        if dist < 5 then
                            sleep = 2
                            DrawMarker(20, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 0.15, 0, 0, 0, 255, false, false, false, 1, false, false, false)
                        end
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        if Drops ~= nil and next(Drops) ~= nil then
            local pos = GetEntityCoords(PlayerPedId(), true)
            for k, v in pairs(Drops) do
                if Drops[k] ~= nil then
                    local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                    if dist < 7.5 then
                        DropsNear[k] = v
                        if dist < 2 then
                            CurrentDrop = k
                        else
                            CurrentDrop = nil
                        end
                    else
                        DropsNear[k] = nil
                    end
                end
            end
        else
            DropsNear = {}
        end
        Citizen.Wait(500)
    end
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    --TriggerServerEvent("inventory:server:LoadDrops")
end)

RegisterNetEvent('inventory:server:RobPlayer')
AddEventHandler('inventory:server:RobPlayer', function(TargetId)
    SendNUIMessage({
        action = "RobMoney",
        TargetId = TargetId,
    })
end)

RegisterNUICallback('RobMoney', function(data, cb)
    TriggerServerEvent("police:server:RobPlayer", data.TargetId)
end)

RegisterNUICallback('Notify', function(data, cb)
    QBCore.Functions.Notify(data.message, data.type)
end)

RegisterNetEvent("inventory:client:OpenInventory")
AddEventHandler("inventory:client:OpenInventory", function(PlayerAmmo, inventory, other, job, gang)
    ToggleHotbar(false)
    SetNuiFocus(true, true)
    --SetNuiFocusKeepInput(true)
    -- DisableAllControlActions(0)
    -- QBCore.Functions.SetNuiFocused(true)

    if other ~= nil then
        currentOtherInventory = other.name
    end

    local plydata = QBCore.Functions.GetPlayerData()

    SendNUIMessage({
        action = "open",
        inventory = inventory,
        slots = 41,
        other = other,
        maxweight = QBCore.Config.Player.MaxWeight,
        Ammo = PlayerAmmo,
        maxammo = Config.MaximumAmmoValues,
        health = GetEntityHealth(PlayerPedId()) - 100,
        armor = GetPedArmour(PlayerPedId()),
        hunger = plydata.metadata.hunger,
        thirst = plydata.metadata.thirst,
        job = job,
        ang = gang
    })
    
    inInventory = true
    -- inInventory = true
    InventoryThread()
end)


function InventoryThread()
    Citizen.CreateThread(function()
        while inInventory do
            local plydata = QBCore.Functions.GetPlayerData()

            SendNUIMessage({
                action = "updatestatus",
                hunger = plydata.metadata.hunger,
                thirst = plydata.metadata.thirst,
                health = GetEntityHealth(PlayerPedId()) - 100,
                armor = GetPedArmour(PlayerPedId()),
            })

            Citizen.Wait(500)
        end
    end)
end

RegisterNetEvent("inventory:client:ShowTrunkPos")
AddEventHandler("inventory:client:ShowTrunkPos", function()
    showTrunkPos = true
end)

RegisterNetEvent("inventory:client:UpdatePlayerInventory")
AddEventHandler("inventory:client:UpdatePlayerInventory", function(isError)
    SendNUIMessage({
        action = "update",
        inventory = QBCore.Functions.GetPlayerData().items,
        maxweight = 1200000,
        slots = 41,
        error = isError,
    })
end)

RegisterNetEvent("inventory:client:CraftItems")
AddEventHandler("inventory:client:CraftItems", function(itemName, itemCosts, amount, toSlot, points)
    local ped = PlayerPedId()
    SendNUIMessage({
        action = "close",
    })
    isCrafting = true
    QBCore.Functions.Progressbar("repair_vehicle", "Reparando...", (math.random(2000, 5000) * amount), false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {
		animDict = "mini@repair",
		anim = "fixing_a_player",
		flags = 16,
	}, {}, {}, function() -- Done
		StopAnimTask(ped, "mini@repair", "fixing_a_player", 1.0)
        TriggerServerEvent("inventory:server:CraftItems", itemName, itemCosts, amount, toSlot, points)
        --TriggerEvent('inventory:client:ItemBox', --QBShared.Items[itemName], 'add')
        isCrafting = false
	end, function() -- Cancel
		StopAnimTask(ped, "mini@repair", "fixing_a_player", 1.0)
        QBCore.Functions.Notify("Fallido!", "error")
        isCrafting = false
	end)
end)

RegisterNetEvent('inventory:client:CraftAttachment')
AddEventHandler('inventory:client:CraftAttachment', function(itemName, itemCosts, amount, toSlot, points)
    local ped = PlayerPedId()
    SendNUIMessage({
        action = "close",
    })
    isCrafting = true
    QBCore.Functions.Progressbar("repair_vehicle", "Reparando...", (math.random(2000, 5000) * amount), false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {
		animDict = "mini@repair",
		anim = "fixing_a_player",
		flags = 16,
	}, {}, {}, function() -- Done
		StopAnimTask(ped, "mini@repair", "fixing_a_player", 1.0)
        TriggerServerEvent("inventory:server:CraftAttachment", itemName, itemCosts, amount, toSlot, points)
       --TriggerEvent('inventory:client:ItemBox', --QBShared.Items[itemName], 'add')
        isCrafting = false
	end, function() -- Cancel
		StopAnimTask(ped, "mini@repair", "fixing_a_player", 1.0)
        QBCore.Functions.Notify("Fallido!", "error")
        isCrafting = false
	end)
end)

RegisterNetEvent("inventory:client:PickupSnowballs")
AddEventHandler("inventory:client:PickupSnowballs", function()
    local ped = PlayerPedId()
    LoadAnimDict('anim@mp_snowball')
    TaskPlayAnim(ped, 'anim@mp_snowball', 'pickup_snowball', 3.0, 3.0, -1, 0, 1, 0, 0, 0)
    QBCore.Functions.Progressbar("pickupsnowball", "Sneeuwballen oprapen..", 1500, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(ped)
        --TriggerServerEvent('QBCore:Server:AddItem', "snowball", 1)
        ----TriggerEvent('inventory:client:ItemBox', --QBShared.Items["snowball"], "add")
    end, function() -- Cancel
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Cancelado!", "error")
    end)
end)

RegisterNetEvent("inventory:client:UseSnowball")
AddEventHandler("inventory:client:UseSnowball", function(amount)
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, GetHashKey("weapon_snowball"), amount, false, false)
    SetPedAmmo(ped, GetHashKey("weapon_snowball"), amount)
    SetCurrentPedWeapon(ped, GetHashKey("weapon_snowball"), true)
end)

RegisterNetEvent("inventory:client:UseWeapon")
AddEventHandler("inventory:client:UseWeapon", function(weaponData, shootbool)
    local ped = PlayerPedId()
    local weaponName = tostring(weaponData.name)
    if currentWeapon == weaponName then
        if currentWeapon:lower() == "weapon_petrolcan" or currentWeapon:lower() == "weapon_fireextinguisher" then
            TriggerServerEvent("weapons:server:UpdateWeaponAmmo", CurrentWeaponData, tonumber(GetAmmoInPedWeapon(ped, GetSelectedPedWeapon(ped))))
        end
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        -- RemoveAllPedWeapons(ped, true)
        TriggerEvent('weapons:client:SetCurrentWeapon', nil, shootbool)
        currentWeapon = nil
    elseif Config.Throwables[weaponName] then
        GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, false)
        SetPedAmmo(ped, GetHashKey(weaponName), 1)
        SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
        TriggerServerEvent('QBCore:Server:RemoveItem', weaponName, 1)
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)

        currentWeapon = weaponName
    elseif weaponName == "weapon_snowball" then
        GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, false)
        SetPedAmmo(ped, GetHashKey(weaponName), 10)
        SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
        TriggerServerEvent('QBCore:Server:RemoveItem', weaponName, 1)
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponName
    else
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        QBCore.Functions.TriggerCallback("weapon:server:GetWeaponAmmo", function(result)
            local ammo = tonumber(result)
            RemoveWeaponFromPed(ped, GetHashKey(weaponName))
            GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, false)
            SetPedAmmo(ped, GetHashKey(weaponName), ammo)
            SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
            --TriggerEvent('origen_weapontint:client:setweapon', weaponData.info.serie)
            if weaponData.info.attachments ~= nil then
                for _, attachment in pairs(weaponData.info.attachments) do
                    if attachment.citizenid ~= nil then
                        if attachment.citizenid == QBCore.Functions.GetPlayerData().citizenid then
                            GiveWeaponComponentToPed(ped, GetHashKey(weaponName), GetHashKey(attachment.component))
                        end
                    else
                        GiveWeaponComponentToPed(ped, GetHashKey(weaponName), GetHashKey(attachment.component))
                    end
                end
            end
            currentWeapon = weaponName
        end, CurrentWeaponData)
    end
end)

WeaponAttachments = {
    ["WEAPON_SNSPISTOL"] = {
        ["extendedclip"] = {
            component = "COMPONENT_SNSPISTOL_CLIP_02",
            label = "Extended Clip",
            item = "pistol_extendedclip",
        },
    },
    ["WEAPON_VINTAGEPISTOL"] = {
        ["suppressor"] = {
            component = "COMPONENT_AT_PI_SUPP",
            label = "Suppressor",
            item = "pistol_suppressor",
        },
        ["extendedclip"] = {
            component = "COMPONENT_VINTAGEPISTOL_CLIP_02",
            label = "Extended Clip",
            item = "pistol_extendedclip",
        },
    },
    ["WEAPON_MICROSMG"] = {
        ["suppressor"] = {
            component = "COMPONENT_AT_AR_SUPP_02",
            label = "Suppressor",
            item = "smg_suppressor",
        },
        ["extendedclip"] = {
            component = "COMPONENT_MICROSMG_CLIP_02",
            label = "Extended Clip",
            item = "smg_extendedclip",
        },
        ["flashlight"] = {
            component = "COMPONENT_AT_PI_FLSH",
            label = "Flashlight",
            item = "smg_flashlight",
        },
        ["scope"] = {
            component = "COMPONENT_AT_SCOPE_MACRO",
            label = "Scope",
            item = "smg_scope",
        },
    },
    ["WEAPON_MINISMG"] = {
        ["extendedclip"] = {
            component = "COMPONENT_MINISMG_CLIP_02",
            label = "Extended Clip",
            item = "smg_extendedclip",
        },
    },
    ["WEAPON_COMPACTRIFLE"] = {
        ["extendedclip"] = {
            component = "COMPONENT_COMPACTRIFLE_CLIP_02",
            label = "Extended Clip",
            item = "rifle_extendedclip",
        },
        ["drummag"] = {
            component = "COMPONENT_COMPACTRIFLE_CLIP_03",
            label = "Drum Mag",
            item = "rifle_drummag",
        },
    },
}

function FormatWeaponAttachments(itemdata)
    local attachments = {}
    itemdata.name = itemdata.name:upper()
    if itemdata.info.attachments ~= nil and next(itemdata.info.attachments) ~= nil then
        for k, v in pairs(itemdata.info.attachments) do
            if WeaponAttachments[itemdata.name] ~= nil then
                for key, value in pairs(WeaponAttachments[itemdata.name]) do
                    if value.component == v.component then
                        table.insert(attachments, {
                            attachment = key,
                            label = value.label
                        })
                    end
                end
            end
        end
    end
    return attachments
end

RegisterNUICallback('GetWeaponData', function(data, cb)

end)

RegisterNUICallback('RemoveAttachment', function(data, cb)
    local ped = PlayerPedId()
    --local WeaponData = --QBShared.Items[data.WeaponData.name]
    local Attachment = WeaponAttachments[WeaponData.name:upper()][data.AttachmentData.attachment]
    
    QBCore.Functions.TriggerCallback('weapons:server:RemoveAttachment', function(NewAttachments)
        if NewAttachments ~= false then
            local Attachies = {}
            RemoveWeaponComponentFromPed(ped, GetHashKey(data.WeaponData.name), GetHashKey(Attachment.component))
            for k, v in pairs(NewAttachments) do
                for wep, pew in pairs(WeaponAttachments[WeaponData.name:upper()]) do
                    if v.component == pew.component then
                        table.insert(Attachies, {
                            attachment = pew.item,
                            label = pew.label,
                        })
                    end
                end
            end
            local DJATA = {
                Attachments = Attachies,
                WeaponData = WeaponData,
            }
            cb(DJATA)
        else
            RemoveWeaponComponentFromPed(ped, GetHashKey(data.WeaponData.name), GetHashKey(Attachment.component))
            cb({})
        end
    end, data.AttachmentData, data.WeaponData)
end)

RegisterNetEvent("inventory:client:CheckWeapon")
AddEventHandler("inventory:client:CheckWeapon", function(weaponName, newinfo)
    local ped = PlayerPedId()
    if currentWeapon == weaponName then 
        if currentWeapon:lower() == "weapon_petrolcan" or currentWeapon:lower() == "weapon_fireextinguisher" then
            TriggerServerEvent("weapons:server:UpdateWeaponAmmo", CurrentWeaponData, tonumber(GetAmmoInPedWeapon(ped, GetSelectedPedWeapon(ped))), newinfo)
        end
        TriggerEvent('weapons:ResetHolster')
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        RemoveAllPedWeapons(ped, true)
        currentWeapon = nil
    end
end)

RegisterNetEvent("inventory:client:AddDropItem")
AddEventHandler("inventory:client:AddDropItem", function(dropId, player, coords)
    local forward = GetEntityForwardVector(GetPlayerPed(GetPlayerFromServerId(player)))
	local x, y, z = table.unpack(coords + forward * 0.5)
    Drops[dropId] = {
        id = dropId,
        coords = {
            x = x,
            y = y,
            z = z - 0.3,
        },
    }
end)

RegisterNUICallback("DropItem", function(cb, post)
    if cb.item == nil then
        return
    end
    TriggerServerEvent("inventory:server:SetInventoryData", "player", 0, cb.item.slot, 1, cb.item.amount, 0, inventoryData)
    post("ok")
end)

RegisterNetEvent("origen_inventory:updatelock")
AddEventHandler("origen_inventory:updatelock", function(s)
    status = s
end)

RegisterNetEvent("inventory:client:RemoveDropItem")
AddEventHandler("inventory:client:RemoveDropItem", function(dropId)
    Drops[dropId] = nil
end)

RegisterNetEvent("inventory:client:DropItemAnim")
AddEventHandler("inventory:client:DropItemAnim", function()
    local ped = PlayerPedId()
    SendNUIMessage({
        action = "close",
    })
    RequestAnimDict("pickup_object")
    while not HasAnimDictLoaded("pickup_object") do
        Citizen.Wait(7)
    end
    TaskPlayAnim(ped, "pickup_object" ,"pickup_low" ,8.0, -8.0, -1, 1, 0, false, false, false )
    Citizen.Wait(2000)
    ClearPedTasks(ped)
end)

RegisterNetEvent("inventory:client:SetCurrentStash")
AddEventHandler("inventory:client:SetCurrentStash", function(stash)
    CurrentStash = stash
end)

RegisterNUICallback('getCombineItem', function(data, cb)
    --cb(--QBShared.Items[data.item])
end)

RegisterCommand("f2fix", function()
    inInventory = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    if InCrafting then
        ClearPedTasks(PlayerPedId())
        InCrafting = false
    end
    --QBCore.Functions.SetNuiFocused(false)
    if currentOtherInventory == "none-inv" then
        CurrentDrop = 0
        CurrentVehicle = nil
        CurrentGlovebox = nil
        CurrentStash = nil
        ClearPedTasks(PlayerPedId())
        return
    end
    if CurrentVehicle ~= nil then
        CloseTrunk()
        TriggerServerEvent("inventory:server:SaveInventory", "trunk", CurrentVehicle)
        CurrentVehicle = nil
    elseif CurrentGlovebox ~= nil then
        TriggerServerEvent("inventory:server:SaveInventory", "glovebox", CurrentGlovebox)
        CurrentGlovebox = nil
    elseif CurrentStash ~= nil then
        TriggerServerEvent("inventory:server:SaveInventory", "stash", CurrentStash)
        CurrentStash = nil
    else
        TriggerServerEvent("inventory:server:SaveInventory", "drop", CurrentDrop)
        CurrentDrop = 0
    end
end)

RegisterNUICallback("CloseInventory", function(data, cb)
    inInventory = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    --QBCore.Functions.SetNuiFocused(false)
    if InCrafting then
        ClearPedTasks(PlayerPedId())
        InCrafting = false
    end
    if currentOtherInventory == "none-inv" then
        CurrentDrop = 0
        CurrentVehicle = nil
        CurrentGlovebox = nil
        CurrentStash = nil
        ClearPedTasks(PlayerPedId())
        return
    end
    if CurrentVehicle ~= nil then
        CloseTrunk()
        TriggerServerEvent("inventory:server:SaveInventory", "trunk", CurrentVehicle)
        TriggerEvent("inventory:client:onclose", CurrentVehicle)
        CurrentVehicle = nil
    elseif CurrentGlovebox ~= nil then
        TriggerServerEvent("inventory:server:SaveInventory", "glovebox", CurrentGlovebox)
        TriggerEvent("inventory:client:onclose", CurrentGlovebox)
        CurrentGlovebox = nil
    elseif CurrentStash ~= nil then
        TriggerServerEvent("inventory:server:SaveInventory", "stash", CurrentStash)
        TriggerEvent("inventory:client:onclose", CurrentStash)
        CurrentStash = nil
    else
        TriggerServerEvent("inventory:server:SaveInventory", "drop", CurrentDrop)
        TriggerEvent("inventory:client:onclose", CurrentDrop)
        CurrentDrop = 0
    end
    Citizen.Wait(100)
end)

RegisterNUICallback("UseItem", function(data, cb)
    TriggerServerEvent("inventory:server:UseItem", data.inventory, data.item)
end)

-- RegisterNUICallback("GetNearPlayers", function(data, cb)
--     local playerPed = PlayerPedId()
--     local players, nearbyPlayer = QBCore.Functions.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
--     local foundPlayers = false
--     local canContinue = true
--     local elements = {}

--     if tonumber(data.count) == 0 then
--         data.count = 1
--     end

--     if tonumber(data.count) > tonumber(data.item.amount) then
--         QBCore.Functions.Notify('Cantidad Invalida')
--         canContinue = false
--     end

--     if canContinue then

--         for i = 1, #players, 1 do
--             if players[i] ~= PlayerId() then
--                 foundPlayers = true

--                 table.insert(elements, {
--                     label = GetPlayerName(players[i]),
--                     player = GetPlayerServerId(players[i])
--                 })
--             end
--         end

--         if not foundPlayers then
--             QBCore.Functions.Notify('No hay jugadores cerca')
--         else
--             SendNUIMessage({
--                 action = "nearPlayers",
--                 foundAny = foundPlayers,
--                 players = elements,
--                 item = data.item,
--                 count = data.count
--             })
--         end

--         cb("ok")
--     end
-- end)

-- RegisterNUICallback("GiveItem", function(data, cb)
--     TriggerServerEvent('inventory:server:giveInventoryItemToPlayer', data)
-- end)

RegisterNUICallback("GiveItem", function(data, cb)
    local player = GetPlayerServerId(NetworkGetPlayerIndexFromPed(PlayerInFront()))

    if player ~= 0 then
        TriggerServerEvent('inventory:server:giveInventoryItemToPlayer', {
            plyXd = player,
            ItemInfoFullHd = data.item,
            NumberOfItem = data.count,
        })
    else
        QBCore.Functions.Notify('No hay jugadores delante tuya')
    end
end)

RegisterNUICallback("DeleteItem", function(data)
    TriggerServerEvent('inventory:server:DeleteItem', data.inventory, data.item, data.count)
end)

------------- DAR ANIMACION ----------------------
loadAnimDict = function(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(5)
	end
end

RegisterNetEvent('inventory:giveItemAnim')
AddEventHandler('inventory:giveItemAnim', function(unarmed)
    if unarmed == true then
        if currentWeapon ~= nil and (currentWeapon:lower() == "weapon_petrolcan" or currentWeapon:lower() == "weapon_fireextinguisher") then
            TriggerServerEvent("weapons:server:UpdateWeaponAmmo", CurrentWeaponData, tonumber(GetAmmoInPedWeapon(ped, GetSelectedPedWeapon(ped))))
        end
        SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)
        TriggerEvent('weapons:client:SetCurrentWeapon', nil, true)
        currentWeapon = nil
    end
	local playerPed = PlayerPedId()
	loadAnimDict('mp_common')
	TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, 8.0, 2000, 50, 0, false, false, false)
end)

RegisterNUICallback("combineItem", function(data)
    Citizen.Wait(150)
    TriggerServerEvent('inventory:server:combineItem', data.reward, data.fromItem, data.toItem)
    --TriggerEvent('inventory:client:ItemBox', --QBShared.Items[data.reward], 'add')
end)

RegisterNUICallback('combineWithAnim', function(data)
    local ped = PlayerPedId()
    local combineData = data.combineData
    local aDict = combineData.anim.dict
    local aLib = combineData.anim.lib
    local animText = combineData.anim.text
    local animTimeout = combineData.anim.timeOut


    QBCore.Functions.Progressbar("combine_anim", animText, animTimeout, false, true, {
        disableMovement = false,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = aDict,
        anim = aLib,
        flags = 16,
    }, {}, {}, function() -- Done
        StopAnimTask(ped, aDict, aLib, 1.0)
        TriggerServerEvent('inventory:server:combineItem', combineData.reward, data.requiredItem, data.usedItem)
       -- TriggerEvent('inventory:client:ItemBox', --QBShared.Items[combineData.reward], 'add')
    end, function() -- Cancel
        StopAnimTask(ped, aDict, aLib, 1.0)
        QBCore.Functions.Notify("Fallido!", "error")
    end)
end)

RegisterNUICallback("SetInventoryData", function(data, cb)
    if data.toInventory == 0 or data.toInventory == "0" then
        local player = PlayerInFront()
        if player ~= 0 and IsPedAPlayer(player) then
            local coords = GetEntityCoords(player)
            if #(GetEntityCoords(PlayerPedId()) - coords) < Config.GiveDistance then
                TriggerServerEvent('inventory:server:giveInventoryItemToPlayer', {
                    plyXd = GetPlayerServerId(NetworkGetPlayerIndexFromPed(player)),
                    slot = data.fromSlot,
                    NumberOfItem = data.fromAmount,
                })
                return
            end
        end
    end
    TriggerServerEvent("inventory:server:SetInventoryData", data.fromInventory, data.toInventory, data.fromSlot, data.toSlot, data.fromAmount, data.toAmount, inventoryData)
end)

RegisterNUICallback("PlayDropSound", function(data, cb)
    PlaySound(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", 0, 0, 1)
end)

RegisterNUICallback("PlayDropFail", function(data, cb)
    PlaySound(-1, "Place_Prop_Fail", "DLC_Dmod_Prop_Editor_Sounds", 0, 0, 1)
end)

function OpenTrunk()
    local vehicle = QBCore.Functions.GetClosestVehicle()
    while (not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b")) do
        RequestAnimDict("amb@prop_human_bum_bin@idle_b")
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_bum_bin@idle_b", "idle_d", 4.0, 4.0, -1, 50, 0, false, false, false)
    if (IsBackEngine(GetEntityModel(vehicle))) then
        SetVehicleDoorOpen(vehicle, 4, false, false)
    else
        SetVehicleDoorOpen(vehicle, 5, false, false)
    end
end

function CloseTrunk()
    local vehicle = QBCore.Functions.GetClosestVehicle()
    while (not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b")) do
        RequestAnimDict("amb@prop_human_bum_bin@idle_b")
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_bum_bin@idle_b", "exit", 4.0, 4.0, -1, 50, 0, false, false, false)
    if (IsBackEngine(GetEntityModel(vehicle))) then
        SetVehicleDoorShut(vehicle, 4, false)
    else
        SetVehicleDoorShut(vehicle, 5, false)
    end
end

function IsBackEngine(vehModel)
    for _, model in pairs(BackEngineVehicles) do
        if GetHashKey(model) == vehModel then
            return true
        end
    end
    return false
end

function ToggleHotbar(toggle)
    local HotbarItems = {
        [1] = QBCore.Functions.GetPlayerData().items[1],
        [2] = QBCore.Functions.GetPlayerData().items[2],
        [3] = QBCore.Functions.GetPlayerData().items[3],
        [4] = QBCore.Functions.GetPlayerData().items[4],
        [5] = QBCore.Functions.GetPlayerData().items[5],
        [41] = QBCore.Functions.GetPlayerData().items[41],
    } 

    if toggle then
        SendNUIMessage({
            action = "toggleHotbar",
            open = true,
            items = HotbarItems
        })
    else
        SendNUIMessage({
            action = "toggleHotbar",
            open = false,
        })
    end
end

function LoadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 5 )
    end
end


RegisterNetEvent('hashashin:usesmoke')
AddEventHandler('hashashin:usesmoke', function()
	SmokeAnimation()
end)

inSmokeAnim = false
canSmokeAgain = true
function SmokeAnimation()
	if canSmokeAgain == false then
		QBCore.Functions.Notify('Acabas de fumar... ¿quieres reventarte los pulmones?')
		return
	end 
	if inSmokeAnim == false then
		local ped = PlayerPedId()
		local anim = "amb@world_human_aa_smoke@male@idle_a"
		local dict = "idle_a"
		if IsPedSittingInAnyVehicle(ped) then 
			if IsPedMale(ped) then
				anim = "amb@world_human_aa_smoke@male@idle_a"
				dict = "idle_a"
			else
				anim = "amb@world_human_leaning@female@smoke@idle_a"
				dict = "idle_a"
			end
			RequestAnimDict(anim)
			local j = 0
        	while not HasAnimDictLoaded(anim) and j < 20 do
				 Citizen.Wait(10)
				 j = j+1
			   end
			TaskPlayAnim( ped, anim, dict, 8.0, -8.0, -1, 49, 0, false, false, false )
			inSmokeAnim = true
		else
			local escenario = "WORLD_HUMAN_SMOKING"
			TaskStartScenarioInPlace(ped, escenario, 0, true)
			inSmokeAnim = true
		end
        Citizen.Wait(30000)
        if IsPedUsingScenario(ped, "WORLD_HUMAN_SMOKING") or IsEntityPlayingAnim(ped, anim, dict, 3) then
            -- QBCore.Functions.Notify('Fumar te ha relajado')
            canSmokeAgain = false
            SetTimeout(60000, function()
                canSmokeAgain = true
            end)
            if IsEntityPlayingAnim(ped, anim, dict, 3) then
                ClearPedTasks(ped)
            elseif IsPedUsingScenario(ped, "WORLD_HUMAN_SMOKING") then
                ClearPedTasks(ped)
            end
            -- TriggerServerEvent('hud:server:RelieveStress', 20)
        else
            QBCore.Functions.Notify('Has tirado el cigarro.')
        end
        if prop ~= nil then
            DeleteObject (prop)
            prop = nil
        end
        inSmokeAnim = false
	else
		QBCore.Functions.Notify('¿Quieres reventarte los pulmones?')
	end

	local playerPed = PlayerPedId()
end


-- WEED ANIMATION --
RegisterNetEvent('play:porro')
AddEventHandler('play:porro', function()
	SmokeWeedAnimation()
end)

inSmokeWeedAnim = false
canSmokeWeedAgain = true
function SmokeWeedAnimation()
	if canSmokeWeedAgain == false then
		QBCore.Functions.Notify('¿Quieres engancharte o qué?')
		return
	end 
	if inSmokeWeedAnim == false then
		local ped = PlayerPedId()
		local anim = "move_m@hipster@a"
		local dict = "idle_a"
		if IsPedSittingInAnyVehicle(ped) then 
            RequestAnimSet("move_m@hipster@a") 
            while not HasAnimSetLoaded("move_m@hipster@a") do
            Citizen.Wait(0)
            end    

            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SMOKING_POT", 0, 1)
            Citizen.Wait(3000)
            ClearPedTasksImmediately(ped)
            SetTimecycleModifier("spectator5")
            SetPedMotionBlur(ped, true)
            SetPedMovementClipset(ped, "move_m@hipster@a", true)
            SetPedIsDrug(ped, true)

            --Efects
            SetRunSprintMultiplierForPlayer(ped, 1.3)

            Wait(300000)

            SetRunSprintMultiplierForPlayer(player, 1.0)		
			inSmokeWeedAnim = true
		else
			local playerPed = PlayerPedId()
            local playerPed = PlayerPedId()
            
            RequestAnimSet("MOVE_M@DRUNK@VERYDRUNK") 

            while not HasAnimSetLoaded("MOVE_M@DRUNK@VERYDRUNK") do
                Citizen.Wait(0)
            end   
             
            TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_SMOKING_POT", 0, 1)
            Citizen.Wait(15000)
            ClearPedTasksImmediately(playerPed)
            SetTimecycleModifier("spectator6")
            SetPedMotionBlur(playerPed, true)
            SetPedMovementClipset(playerPed, "MOVE_M@DRUNK@VERYDRUNK", true)
            SetPedIsDrunk(playerPed, true)
            AnimpostfxPlay("ChopVision", 10000001, true)
            ShakeGameplayCam("DRUNK_SHAKE", 1.0)
            
            SetEntityHealth(PlayerPedId(), 200)
            SetPedArmour(PlayerPedId(), 50)
            
		end
        Citizen.Wait(30000)
        
        -- QBCore.Functions.Notify('Fumarte un peta te ha relajado')
        canSmokeWeedAgain = false
        SetTimeout(60000, function()
            canSmokeWeedAgain = true
        end)

        ClearPedTasks(ped)

        -- TriggerServerEvent('hud:server:RelieveStress', 50)

        QBCore.Functions.Notify('Has tirado el porro.')

        Citizen.Wait(30000)

        --Time of effect
        --  after wait stop all effects
        SetPedMoveRateOverride(PlayerId(),1.0)
        SetRunSprintMultiplierForPlayer(PlayerId(),1.0)
        SetPedIsDrunk(PlayerPedId(), false)		
        SetPedMotionBlur(playerPed, false)
        ResetPedMovementClipset(PlayerPedId())
        AnimpostfxStopAll()
        ShakeGameplayCam("DRUNK_SHAKE", 0.0)
        SetTimecycleModifierStrength(0.0)

        inSmokeWeedAnim = true

        if prop ~= nil then
            DeleteObject (prop)
            prop = nil
        end
        inSmokeWeedAnim = false
	else
		QBCore.Functions.Notify('¿Quieres engancharte o qué?')
	end

	local playerPed = PlayerPedId()
end

local authorizedEvents = {'qb-radialmenu:ToggleProps', 'qb-radialmenu:ToggleClothing', 'qb-inventory:client:searchclosest', 'qb-phone:client:GiveContactDetails', 'origen_menu:pressedIdCardClose'}

function isAuthorized(event)
    for k,v in pairs(authorizedEvents) do
        if v == event then
            return true
        end
    end
    return false
end

-- Botones de acciones rapidas
RegisterNUICallback('inventory_options', function(data)
    local isAuthorized = isAuthorized(data.event)
    if isAuthorized then
        data.action = data.action or ''
        TriggerEvent(data.event, data.action)
    else
        print('Ha ocurrido un error')
    end
end)

function SearchClosest()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance <= 3.0 and distance > 0 then
        if IsEntityPlayingAnim(GetPlayerPed(player), "random@mugging3", "handsup_standing_base", 3) == 1 or IsEntityPlayingAnim(GetPlayerPed(player), "mp_arresting", "idle", 3) == 1 or IsEntityPlayingAnim(GetPlayerPed(player), "combat@damage@writhe", "writhe_loop", 3) == 1 or IsEntityPlayingAnim(GetPlayerPed(player), "veh@low@front_ps@idle_duck", "sit", 3) == 1 or IsEntityPlayingAnim(GetPlayerPed(player), "move_injured_ground", "front_loop", 3) == 1 or IsEntityPlayingAnim(GetPlayerPed(player), "dead", "dead_a", 3) == 1 or IsEntityDead(GetPlayerPed(player)) then
            ExecuteCommand('me le cachea')
            local playerId = GetPlayerServerId(player)
            QBCore.Functions.Progressbar("search_player_inv", "Cacheando", 3000, false, true, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "anim@gangops@facility@servers@bodysearch@",
                anim = "player_search",
                flags = 49,
            }, {}, {}, function()
                StopAnimTask(PlayerPedId(), "anim@gangops@facility@servers@bodysearch@", "player_search", 1.0)
                TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", playerId)
                StartSearchDistance(playerId)
            end)
        else
            QBCore.Functions.Notify("La persona debe tener las manos levantadas o estar esposado", "error")
        end
    else
        QBCore.Functions.Notify("No hay nadie cerca", "error")
    end
end

RegisterNetEvent('qb-inventory:client:searchclosest', SearchClosest)
RegisterCommand("cachear", SearchClosest)

StartSearchDistance = function(id)
    Citizen.Wait(300)
    while true do
        Citizen.Wait(50)
        local playerIdx = GetPlayerFromServerId(id)
        local ped = GetPlayerPed(playerIdx)
        local coordsPed = GetEntityCoords(ped)
        local playerCoords = GetEntityCoords(PlayerPedId())
        if inInventory == false then
            break
        else
            if #(coordsPed - playerCoords) > 4 then
                TriggerEvent('qb-inventory:closeInv')
                QBCore.Functions.Notify("Has dejado de cachear porque estas muy lejos del sujeto!", "error")
                break
            end
        end
    end
end

RegisterNetEvent('inventory:client:SetCraftResult', function(slot, item, amount, info)
    if item then
        local item = --QBShared.Items[item]
        SendNUIMessage({
            action = "SetCraftResult",
            lastslot = slot,
            fromData = {
                name = item.name,
                label = item.label,
                amount = amount,
                type = item.type,
                description = item.description,
                image = item.image,
                weight = item.weight,
                info = info and info or {},
                useable = item.useable,
                unique = item.unique,
                slot = slot
            }
        })
    else
        SendNUIMessage({
            action = "ClearCraftResult",
            lastslot = slot
        })
    end
end)

RegisterNetEvent('inventory:client:UpdateCraftItems', function(items, clear)
    for k, v in pairs(items) do
        local item = --QBShared.Items[v.name]
        SendNUIMessage({
            action = "UpdateCraftItems",
            slot = k,
            fromData = {
                name = item.name,
                label = item.label,
                amount = v.amount,
                type = item.type,
                description = item.description,
                image = item.image,
                weight = item.weight,
                info = {},
                useable = item.useable,
                unique = item.unique,
                slot = k
            }
        })
    end
    for _, v in pairs(clear) do
        SendNUIMessage({
            action = "ClearCraftItems",
            slot = v
        })
    end
end)

-- Crafting system

RegisterNetEvent("qb-inventory:police:weapfingers", function()
    TriggerServerEvent("inventory:server:OpenInventory", "origen_craft", "police_fingers", {
        slots = 2
    })
    InCrafting = true
end)

exports('GetCurrentWeapon', function()
    return CurrentWeaponData
end)

function PlayerInFront()
	local playerPedId = PlayerPedId()
	local pos = GetEntityCoords(playerPedId)
	local entityWorld = GetOffsetFromEntityInWorldCoords(playerPedId, 0.0, 4.0, 0.0)
	local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 4, playerPedId, 0)
	local a, b, c, d, result = GetRaycastResult(rayHandle)
	return result
end

RegisterNUICallback("TriggerCallback", function(data, cb)
    QBCore.Functions.TriggerCallback(data.name, function(retval)
        cb(retval)
    end, data)
end)

RegisterNUICallback("ExecuteCommand", function(data, cb)
    ExecuteCommand(data.command)
    cb(true)
end)

RegisterNUICallback("ExecuteEvent", function(data, cb)
    TriggerEvent(data.event)
    cb(true)
end)