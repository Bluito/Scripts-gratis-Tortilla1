--[[
    🔥 Sistema simple de trabajo
    💻 Autor: El_tortilla1
    📅 Fecha: 2025-06-13
    🧠 Script de práctica - Prohibida su venta sin autorización
    📌 Discord: Tortilla Scripts
]]

local QBCore = exports['qb-core']:GetCoreObject()

local npcModelZonas = {
    { model = GetHashKey("s_m_m_security_01"), coords = vector3(967.362, -133.232, 74.2) },
    { model = GetHashKey("s_m_y_blackops_01"), coords = vector3(-1219.39, -499.99, 31.16) },
    { model = GetHashKey("s_f_y_sheriff_01"), coords = vector3(-1108.43, 373.07, 69.3) },
    { model = GetHashKey("s_m_m_paramedic_01"), coords = vector3(-1475.81, 490.02, 117.18) }
}

local maletinModel = GetHashKey("prop_ld_case_01")

local npcEntities = {}
local maletinObject = nil
local maletinBlip = nil
local isWorking = false
local tieneMaletin = false

local npcInicio = nil
local npcInicioCoords = vector3(-1262.38, -1554.52, 4.31)
local npcInicioModel = GetHashKey("s_m_m_ammucountry")

-- Relación hostil
AddRelationshipGroup("HATES_PLAYER")
SetRelationshipBetweenGroups(5, GetHashKey("HATES_PLAYER"), GetHashKey("PLAYER"))
SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("HATES_PLAYER"))

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
    SetPedAlertness(npc, 3)
    SetPedAsEnemy(npc, true)
    SetPedCanRagdollFromPlayerImpact(npc, false)
    SetPedDropsWeaponsWhenDead(npc, false)
    SetPedArmour(npc, 100)
    GiveWeaponToPed(npc, GetHashKey("WEAPON_COMBATPISTOL"), 255, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    ClearPedTasks(npc)
    TaskCombatHatedTargetsAroundPed(npc, 100.0, 0)

    return npc
end

local function patrullarNPC(npc, center)
    Citizen.CreateThread(function()
        while DoesEntityExist(npc) and not IsEntityDead(npc) do
            local x = center.x + math.random(-10, 10)
            local y = center.y + math.random(-10, 10)
            TaskWanderInArea(npc, x, y, center.z, 15.0, 10.0, 1.0)
            TaskCombatHatedTargetsAroundPed(npc, 100.0, 0)
            Citizen.Wait(10000)
        end
    end)
end

-- Spawn NPC inicio
Citizen.CreateThread(function()
    RequestModel(npcInicioModel)
    while not HasModelLoaded(npcInicioModel) do Citizen.Wait(10) end

    npcInicio = CreatePed(4, npcInicioModel, npcInicioCoords.x, npcInicioCoords.y, npcInicioCoords.z - 1.0, 0.0, false, true)
    SetEntityInvincible(npcInicio, true)
    FreezeEntityPosition(npcInicio, true)
    SetBlockingOfNonTemporaryEvents(npcInicio, true)
    TaskStartScenarioInPlace(npcInicio, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
end)

local function crearMaletin()
    local zona = npcModelZonas[math.random(#npcModelZonas)]
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
    AddTextComponentString("Maletín para recoger")
    EndTextCommandSetBlipName(maletinBlip)

    for _, npc in pairs(npcEntities) do
        if DoesEntityExist(npc) then DeleteEntity(npc) end
    end
    npcEntities = {}

    for i = 1, 5 do
        local offset = vector3(zona.coords.x + math.random(-10,10), zona.coords.y + math.random(-10,10), zona.coords.z)
        local npc = spawnNPC(zona.model, offset)
        patrullarNPC(npc, offset)
        table.insert(npcEntities, npc)
    end

    return zona.coords
end

local maletinCoords = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if not isWorking then
            if #(playerCoords - npcInicioCoords) < 3.0 then
                DrawText3D(npcInicioCoords.x, npcInicioCoords.y, npcInicioCoords.z + 1.0, "~g~E~w~ Hablar para iniciar trabajo")
                if IsControlJustReleased(0, 38) then
                    isWorking = true
                    maletinCoords = crearMaletin()
                    tieneMaletin = false
                    QBCore.Functions.Notify('Trabajo iniciado: recoge el maletín.', 'success')
                end
            end
        else
            if not tieneMaletin and maletinObject then
                if #(playerCoords - GetEntityCoords(maletinObject)) < 3.0 then
                    DrawText3D(maletinCoords.x, maletinCoords.y, maletinCoords.z + 1.0, "~g~E~w~ Recoger maletín")
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent("maletin:recogerIntento")
                    end
                end
            end

            if tieneMaletin then
                if #(playerCoords - npcInicioCoords) < 3.0 then
                    DrawText3D(npcInicioCoords.x, npcInicioCoords.y, npcInicioCoords.z + 1.0, "~g~E~w~ Entregar maletín")
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent("maletin:entregarMaletin")
                        isWorking = false
                        tieneMaletin = false
                        if maletinBlip then RemoveBlip(maletinBlip) end
                        if maletinObject then DeleteObject(maletinObject) end
                        for _, npc in pairs(npcEntities) do
                            if DoesEntityExist(npc) then DeleteEntity(npc) end
                        end
                        npcEntities = {}
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("maletin:confirmado", function()
    tieneMaletin = true
    if maletinObject then DeleteObject(maletinObject) end
    if maletinBlip then RemoveBlip(maletinBlip) end
    QBCore.Functions.Notify("Has recogido el maletín.", "success")
end)

RegisterNetEvent("maletin:entregado", function()
    QBCore.Functions.Notify("Has entregado el maletín. Has ganado $500.", "success")
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 150, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
