--[[ 
    🔥 Trabajo de entregar paquetes, este scrip solo funcionar con QBCore
    💻 Autor: El_tortilla1
    📅 Fecha: 2025-06-17
    🧠 Script de práctica - Prohibida su venta sin autorización
    📌 Discord: Tortilla scripts (BETA)
]]

local QBCore = exports['qb-core']:GetCoreObject()

local enTrabajo, recogido = false, false
local jobDeliveryCoords = nil
local jobBlip = nil
local vehiculoTrabajo = nil
local caja = nil
local npcEntrega = nil

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0, 0)
    ClearDrawOrigin()
end

-- Crear blip de inicio
local blip = AddBlipForCoord(Config.NPC.coords)
SetBlipSprite(blip, 478)
SetBlipColour(blip, 5)
SetBlipScale(blip, 0.8)
BeginTextCommandSetBlipName("STRING")
AddTextComponentString("Entrega Mensajero")
EndTextCommandSetBlipName(blip)

-- Spawnear NPC de inicio
CreateThread(function()
    local model = Config.NPC.model
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(10) end
    local ped = CreatePed(4, GetHashKey(model), Config.NPC.coords, Config.NPC.heading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end)

-- Interacción con NPC sin parpadeo
CreateThread(function()
    while true do
        Wait(0)
        if not enTrabajo then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local dist = #(pos - Config.NPC.coords)
            if dist <= 2.5 then
                DrawText3D(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z + 1.0, "~y~[E] ~w~Iniciar trabajo de entrega")
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("Inicio")
                end
            end
        else
            Wait(500)
        end
    end
end)

-- Evento de inicio de trabajo
RegisterNetEvent("cliente:IniciarTrabajo", function(coords)
    enTrabajo, recogido = true, false
    jobDeliveryCoords = vector3(coords.x, coords.y, coords.z)

    QBCore.Functions.SpawnVehicle(Config.Car.modelcar, function(veh)
        vehiculoTrabajo = veh
        SetVehicleNumberPlateText(veh, "TRABAJO")
        SetEntityAsMissionEntity(veh, true, true)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    end, Config.Car.coordsCar, Config.Car.headingCar, true)

    if jobBlip then RemoveBlip(jobBlip) end
    jobBlip = AddBlipForCoord(jobDeliveryCoords)
    SetBlipSprite(jobBlip, 1)
    SetBlipColour(jobBlip, 2)
    SetBlipScale(jobBlip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Zona de entrega")
    EndTextCommandSetBlipName(jobBlip)
    SetBlipRoute(jobBlip, true)
end)

RegisterNetEvent("cliente:paqueteRecogido", function()
    recogido = true
    if jobBlip then RemoveBlip(jobBlip) end
    jobBlip = AddBlipForCoord(jobDeliveryCoords)
    SetBlipSprite(jobBlip, 1)
    SetBlipColour(jobBlip, 3)
    SetBlipScale(jobBlip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Entrega aquí")
    EndTextCommandSetBlipName(jobBlip)
    SetBlipRoute(jobBlip, true)
end)

RegisterNetEvent("cliente:TrabajoTerminado", function(completado)
    if caja and DoesEntityExist(caja) then
        DeleteObject(caja)
        caja = nil
    end
    if npcEntrega and DoesEntityExist(npcEntrega) then
        TaskWanderStandard(npcEntrega, 10.0, 10)
        npcEntrega = nil
    end
    if jobBlip then RemoveBlip(jobBlip) end
    vehiculoTrabajo = nil
    jobDeliveryCoords = nil
    enTrabajo, recogido = false, false

    if completado then
        QBCore.Functions.Notify("Has entregado la caja con éxito.", "success")
    else
        QBCore.Functions.Notify("Trabajo cancelado.", "error")
    end
end)

-- Loop de interacción
CreateThread(function()
    while true do
        local sleep = 1000
        if enTrabajo and jobDeliveryCoords then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)

            -- Interacción con maletero
            if not recogido and vehiculoTrabajo and DoesEntityExist(vehiculoTrabajo) then
                local vehPos = GetEntityCoords(vehiculoTrabajo)
                local distToVeh = #(pos - vehPos)
                if distToVeh <= 4.0 and not IsPedInAnyVehicle(ped, false) then
                    local maletero = GetOffsetFromEntityInWorldCoords(vehiculoTrabajo, 0.0, -2.5, 0.0)
                    DrawMarker(1, maletero.x, maletero.y, maletero.z - 1.0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 255, 0, 150, false, true, 2)
                    DrawText3D(maletero.x, maletero.y, maletero.z + 0.4, "~y~[E] ~w~Sacar caja del maletero")
                    if IsControlJustReleased(0, 38) then
                        RequestAnimDict("anim@heists@box_carry@")
                        while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(10) end
                        TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 51, 0, false, false, false)
                        caja = CreateObject(GetHashKey("prop_box_wood02a"), pos.x, pos.y, pos.z + 0.5, true, true, true)
                        AttachEntityToEntity(caja, ped, GetPedBoneIndex(ped, 28422), 0.1, 0, 0, 0, 270, 0, true, true, false, true, 1, true)

                        SetVehicleDoorOpen(vehiculoTrabajo, 5, false, false)
                        TriggerServerEvent("script:validarRecogida", pos)

                        SetTimeout(1500, function()
                            SetVehicleDoorShut(vehiculoTrabajo, 5, false)
                        end)
                    end
                    sleep = 0
                end
            end

            -- Entrega
            if recogido and #(pos - jobDeliveryCoords) <= 3.0 then
                if not npcEntrega then
                    local model = Config.EntregaNPC.model
                    RequestModel(GetHashKey(model))
                    while not HasModelLoaded(GetHashKey(model)) do Wait(10) end
                    npcEntrega = CreatePed(4, GetHashKey(model), jobDeliveryCoords.x, jobDeliveryCoords.y, jobDeliveryCoords.z - 1.0, 0.0, false, true)
                    FreezeEntityPosition(npcEntrega, true)
                    SetEntityInvincible(npcEntrega, true)
                    SetBlockingOfNonTemporaryEvents(npcEntrega, true)
                end
                DrawMarker(1, jobDeliveryCoords.x, jobDeliveryCoords.y, jobDeliveryCoords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.5, 0, 255, 0, 150, false, true, 2)
                DrawText3D(jobDeliveryCoords.x, jobDeliveryCoords.y, jobDeliveryCoords.z + 1.2, "~y~[E] ~w~Entregar caja")
                if IsControlJustReleased(0, 38) then
                    ClearPedTasks(ped)
                    RequestAnimDict("mp_common")
                    while not HasAnimDictLoaded("mp_common") do Wait(10) end
                    TaskPlayAnim(ped, "mp_common", "givetake1_a", 8.0, -8.0, 2000, 0, 0, false, false, false)
                    Wait(2000)
                    TriggerServerEvent("script:validarEntrega", GetEntityCoords(ped))
                end
                sleep = 0
            end
        end
        Wait(sleep)
    end
end)