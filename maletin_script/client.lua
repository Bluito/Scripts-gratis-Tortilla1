--[[
    🔥 Sistema simple de trabajo
    💻 Autor: El_tortilla1
    📅 Fecha: 2025-06-13
    🧠 Script de práctica - Prohibida su venta sin autorización
    📌 Discord: Tortilla Scripts
]]

local QBCore = exports['qb-core']:GetCoreObject()

local npcZonas = {
    { model = GetHashKey("s_m_m_security_01"), coords = vector3(967.362, -133.232, 74.2) },
    { model = GetHashKey("s_m_y_blackops_01"), coords = vector3(-1219.39, -499.99, 31.16) },
    { model = GetHashKey("s_f_y_sheriff_01"), coords = vector3(-1108.43, 373.07, 69.3) },
    { model = GetHashKey("s_m_m_paramedic_01"), coords = vector3(-1475.81, 490.02, 117.18) }
}

local maletinModel = GetHashKey("prop_ld_case_01")

local npcInicioModel = GetHashKey("s_m_m_ammucountry")
local npcInicioCoords = vector3(-1262.38, -1554.52, 4.31)

local isWorking, tieneMaletin = false, false
local maletinObject, maletinBlip = nil, nil
local npcEntities, maletinCoords = {}, nil
local npcInicio = nil

-- Relación hostil para PNJs armados
AddRelationshipGroup("HATES_PLAYER")
SetRelationshipBetweenGroups(5, `HATES_PLAYER`, `PLAYER`)
SetRelationshipBetweenGroups(5, `PLAYER`, `HATES_PLAYER`)

-- Función para dibujar texto 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextOutline()
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentString(text)
        EndTextCommandDisplayText(_x, _y)
    end
end

-- Crear NPC de inicio
Citizen.CreateThread(function()
    RequestModel(npcInicioModel)
    while not HasModelLoaded(npcInicioModel) do Citizen.Wait(10) end

    npcInicio = CreatePed(4, npcInicioModel, npcInicioCoords.x, npcInicioCoords.y, npcInicioCoords.z - 1.0, 0.0, false, true)
    FreezeEntityPosition(npcInicio, true)
    SetEntityInvincible(npcInicio, true)
    SetBlockingOfNonTemporaryEvents(npcInicio, true)
    TaskStartScenarioInPlace(npcInicio, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
end)

-- Función para crear NPC hostil
local function spawnNPC(model, coords)
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(10) end

    local npc = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, 0.0, true, true)
    SetPedRelationshipGroupHash(npc, GetHashKey("HATES_PLAYER"))
    SetPedCombatAttributes(npc, 46, true)
    SetPedFleeAttributes(npc, 0, 0)
    SetPedCombatMovement(npc, 3)
    SetPedCombatAbility(npc, 2)
    SetPedCombatRange(npc, 2)
    SetPedAccuracy(npc, 75)
    SetPedAsEnemy(npc, true)
    SetPedArmour(npc, 100)
    GiveWeaponToPed(npc, `WEAPON_COMBATPISTOL`, 255, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    TaskCombatHatedTargetsAroundPed(npc, 100.0, 0)
    return npc
end

-- Patrulla de NPC
local function patrullarNPC(npc, center)
    Citizen.CreateThread(function()
        while DoesEntityExist(npc) and not IsEntityDead(npc) do
            TaskWanderInArea(npc, center.x, center.y, center.z, 15.0, 10.0, 1.0)
            TaskCombatHatedTargetsAroundPed(npc, 100.0, 0)
            Citizen.Wait(10000)
        end
    end)
end

-- Crear maletín y enemigos
local function crearMaletin()
    local zona = npcZonas[math.random(#npcZonas)]

    RequestModel(maletinModel)
    while not HasModelLoaded(maletinModel) do Citizen.Wait(10) end

    if maletinObject then DeleteObject(maletinObject) end
    maletinObject = CreateObject(maletinModel, zona.coords.x, zona.coords.y, zona.coords.z, true, true, true)
    PlaceObjectOnGroundProperly(maletinObject)
    FreezeEntityPosition(maletinObject, true)

    if maletinBlip then RemoveBlip(maletinBlip) end
    maletinBlip = AddBlipForCoord(zona.coords)
    SetBlipSprite(maletinBlip, 487)
    SetBlipColour(maletinBlip, 1)
    SetBlipRoute(maletinBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Maletín")
    EndTextCommandSetBlipName(maletinBlip)

    -- Limpiar NPCs viejos
    for _, npc in ipairs(npcEntities) do
        if DoesEntityExist(npc) then DeleteEntity(npc) end
    end
    npcEntities = {}

    -- Crear nuevos enemigos
    for i = 1, 5 do
        local offset = vector3(zona.coords.x + math.random(-10,10), zona.coords.y + math.random(-10,10), zona.coords.z)
        local npc = spawnNPC(zona.model, offset)
        patrullarNPC(npc, offset)
        table.insert(npcEntities, npc)
    end

    return zona.coords
end

-- Interacción principal
Citizen.CreateThread(function()
    while true do
        local sleep = 1500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if not isWorking and #(coords - npcInicioCoords) < 3.0 then
            sleep = 1
            DrawText3D(npcInicioCoords.x, npcInicioCoords.y, npcInicioCoords.z + 1.0, "~g~E~w~ Iniciar trabajo")
            if IsControlJustReleased(0, 38) then
                isWorking = true
                tieneMaletin = false
                maletinCoords = crearMaletin()
                QBCore.Functions.Notify('Trabajo iniciado. Ve a recoger el maletín.', 'success')
            end
        elseif isWorking then
            if not tieneMaletin and maletinObject then
                local maletCoords = GetEntityCoords(maletinObject)
                if #(coords - maletCoords) < 2.5 then
                    sleep = 1
                    DrawText3D(maletCoords.x, maletCoords.y, maletCoords.z + 1.0, "~g~E~w~ Recoger maletín")
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent("maletin:recogerIntento")
                    end
                end
            elseif tieneMaletin and #(coords - npcInicioCoords) < 3.0 then
                sleep = 1
                DrawText3D(npcInicioCoords.x, npcInicioCoords.y, npcInicioCoords.z + 1.0, "~g~E~w~ Entregar maletín")
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("maletin:entregarMaletin")
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Confirmación de recogida desde el servidor
RegisterNetEvent("maletin:confirmado", function()
    tieneMaletin = true
    if maletinObject then DeleteObject(maletinObject) end
    if maletinBlip then RemoveBlip(maletinBlip) end
    QBCore.Functions.Notify("Has recogido el maletín.", "success")
end)

-- Confirmación de entrega desde el servidor
RegisterNetEvent("maletin:entregado", function()
    QBCore.Functions.Notify("Maletín entregado. Has ganado $500.", "success")
    tieneMaletin = false
    isWorking = false

    if maletinObject then DeleteObject(maletinObject) end
    if maletinBlip then RemoveBlip(maletinBlip) end
    for _, npc in ipairs(npcEntities) do
        if DoesEntityExist(npc) then DeleteEntity(npc) end
    end
    npcEntities = {}
end)
