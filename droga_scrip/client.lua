--[[ 
    🔥 Sistema de droga, este scrip solo funcionar con QBCore
    💻 Autor: El_tortilla1
    📅 Fecha: 2025-06-13
    🧠 Script de práctica - Prohibida su venta sin autorización
    📌 Discord: Tortilla Scripts
]]

local QBCore = exports['qb-core']:GetCoreObject()

local blip = AddBlipForCoord(2222.0, 5576.0, 0.0)

SetBlipSprite(blip, 140)          -- Ícono del blip (número)
SetBlipDisplay(blip, 4)              -- Mostrar siempre en mapa (4 = visible siempre)
SetBlipScale(blip, 0.8)              -- Tamaño del blip
SetBlipColour(blip, 2)           -- Color del blip
SetBlipAsShortRange(blip, true)      -- Solo se ve cerca (true) o global (false)
BeginTextCommandSetBlipName("STRING")
AddTextComponentString("Marihuana zone") -- Nombre que aparece
EndTextCommandSetBlipName(blip)

local blip2 = AddBlipForCoord(363.06, -67.11, 0.0)

SetBlipSprite(blip2, 140)          -- Ícono del blip (número)
SetBlipDisplay(blip2, 4)              -- Mostrar siempre en mapa (4 = visible siempre)
SetBlipScale(blip2, 0.8)              -- Tamaño del blip
SetBlipColour(blip2, 2)           -- Color del blip
SetBlipAsShortRange(blip2, true)      -- Solo se ve cerca (true) o global (false)
BeginTextCommandSetBlipName("STRING")
AddTextComponentString("Dealer") -- Nombre que aparece
EndTextCommandSetBlipName(blip2)

local plantObjects = {}
local plants = {}
local plantModel = "prop_weed_01"
local isInteracting = false

-- NPC vendedor
local dealerModel = "g_m_y_mexgoon_01"
local dealerCoords = vector4(363.06, -67.11, 68.18, 200.34)
local dealerPed = nil

-- Funciones utilitarias
local function loadModel(model)
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(10) end
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function playPlantEffect(coords)
    UseParticleFxAssetNextCall("core")
    StartParticleFxNonLoopedAtCoord("ent_sht_plant", coords.x, coords.y, coords.z + 0.3, 0.0, 0.0, 0.0, 0.4, false, false, false)
end

local function playSound(coords)
    PlaySoundFromCoord(-1, "Blanchwood_Plant_Cut", coords.x, coords.y, coords.z, "DLC_GR_Bunker_Jobs_Sounds", false, 0, false)
end

local function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoords()
    local dist = #(vector3(x, y, z) - camCoords)
    local scale = (1 / dist) * 1.2 * (1 / GetGameplayCamFov()) * 100
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 230)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function spawnPlant(index, coords)
    loadModel(plantModel)
    local obj = CreateObject(GetHashKey(plantModel), coords.x, coords.y, coords.z - 1.0, false, false, false)
    SetEntityHeading(obj, 0.0)
    FreezeEntityPosition(obj, true)
    plantObjects[index] = obj
end

local function deletePlant(index)
    local obj = plantObjects[index]
    if obj and DoesEntityExist(obj) then
        DeleteObject(obj)
        plantObjects[index] = nil
        print("[droga_scrip] Planta eliminada correctamente. Index:", index)
    else
        print("[droga_scrip] No se pudo eliminar la planta. Index:", index, "Objeto:", obj)
    end
end

local function spawnDealer()
    loadModel(dealerModel)
    dealerPed = CreatePed(0, GetHashKey(dealerModel), dealerCoords.x, dealerCoords.y, dealerCoords.z - 1.0, dealerCoords.w, false, true)
    FreezeEntityPosition(dealerPed, true)
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
end

RegisterNetEvent("droga_scrip:respawnPlant", function(index)
    if plants[index] then
        spawnPlant(index, plants[index].coords)
    end
end)

RegisterNetEvent("droga_scrip:removePlant", function(index)
    deletePlant(index)
end)

CreateThread(function()
    QBCore.Functions.TriggerCallback('droga_scrip:getPlants', function(serverPlants)
        plants = serverPlants
        for index, plant in pairs(plants) do
            spawnPlant(index, plant.coords)
        end
    end)
    spawnDealer()
end)

CreateThread(function()
    while true do
        local sleep = 1500
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)

        for index, plant in pairs(plants) do
            local plantObj = plantObjects[index]
            if plantObj then
                local dist = #(pedCoords - plant.coords)
                if dist < 2.5 then
                    sleep = 0
                    Draw3DText(plant.coords.x, plant.coords.y, plant.coords.z, "[E] Recoger planta")

                    if IsControlJustReleased(0, 38) and not isInteracting then
                        isInteracting = true

                        QBCore.Functions.Progressbar("recolectar_marihuana", "Recolectando planta...", 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = "amb@world_human_gardener_plant@male@base",
                            anim = "base",
                            flags = 1,
                        }, {}, {}, function()
                            ClearPedTasks(ped)
                            playSound(plant.coords)
                            playPlantEffect(plant.coords)
                            TriggerServerEvent("droga_scrip:recogerPlanta", index)
                            isInteracting = false
                        end, function()
                            ClearPedTasks(ped)
                            QBCore.Functions.Notify("Has cancelado la recolección.", "error")
                            isInteracting = false
                        end)
                    end
                end
            end
        end

        if dealerPed and #(pedCoords - vector3(dealerCoords.x, dealerCoords.y, dealerCoords.z)) < 2.0 then
            sleep = 0
            Draw3DText(dealerCoords.x, dealerCoords.y, dealerCoords.z + 1.0, "[E] Vender Marihuana")
            if IsControlJustReleased(0, 38) then
                TriggerServerEvent("droga_scrip:venderMarihuana")
            end
        end

        Wait(sleep)
    end
end)
