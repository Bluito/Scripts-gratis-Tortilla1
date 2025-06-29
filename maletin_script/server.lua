--[[
    🔥 Sistema simple de trabajo
    💻 Autor: El_tortilla1
    📅 Fecha: 2025-06-13
    🌐 Proyecto educativo - Prohibida su venta sin autorización
    📌 Discord: Tortilla Scripts
]]

print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("^2 Proyecto de practica - El_tortilla1")
print("^5 Propósito: Portafolio, no comercial")
print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━^7")

local QBCore = exports['qb-core']:GetCoreObject()

local estadoTrabajoJugador = {}

RegisterNetEvent("maletin:recogerIntento", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not estadoTrabajoJugador[src] then
        estadoTrabajoJugador[src] = { tieneMaletin = false, cobroRealizado = false }
    end

    local datos = estadoTrabajoJugador[src]

    if datos.tieneMaletin or datos.cobroRealizado then
        print("[Alerta] Jugador " .. src .. " intentó recoger el maletín sin permiso.")
        return
    end

    datos.tieneMaletin = true
    TriggerClientEvent("maletin:confirmado", src)
end)

RegisterNetEvent("maletin:entregarMaletin", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddMoney("cash", 500, "Pago por entregar maletín")
        TriggerClientEvent("maletin:entregado", src)
    end

    estadoTrabajoJugador[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    estadoTrabajoJugador[src] = nil
end)
