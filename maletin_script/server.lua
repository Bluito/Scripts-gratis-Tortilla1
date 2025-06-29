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

-- Tabla por jugador para seguimiento
local estadoTrabajoJugador = {}

-- Evento: Jugador intenta recoger el maletín
RegisterNetEvent("maletin:recogerIntento", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Inicializar estado si no existe
    if not estadoTrabajoJugador[src] then
        estadoTrabajoJugador[src] = {
            tieneMaletin = false,
            cobroRealizado = false
        }
    end

    local datos = estadoTrabajoJugador[src]

    -- Protección: evitar doble maletín
    if datos.tieneMaletin or datos.cobroRealizado then
        print("[AntiExploit] Jugador " .. src .. " intentó recoger maletín cuando ya lo tenía o ya cobró.")
        TriggerClientEvent("QBCore:Notify", src, "Ya estás en medio de un trabajo.", "error")
        return
    end

    -- Asignar maletín
    datos.tieneMaletin = true
    datos.cobroRealizado = false
    TriggerClientEvent("maletin:confirmado", src)
end)

-- Evento: Jugador entrega el maletín
RegisterNetEvent("maletin:entregarMaletin", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not estadoTrabajoJugador[src] then return end

    local datos = estadoTrabajoJugador[src]

    if datos.tieneMaletin and not datos.cobroRealizado then
        datos.tieneMaletin = false
        datos.cobroRealizado = true

        Player.Functions.AddMoney("cash", 500, "Pago por entregar maletín")
        TriggerClientEvent("maletin:entregado", src)
    else
        print("[AntiExploit] Jugador " .. src .. " intentó entregar sin tener maletín o ya había cobrado.")
        TriggerClientEvent("QBCore:Notify", src, "No puedes entregar el maletín en este momento.", "error")
    end
end)

-- Limpieza al salir el jugador
AddEventHandler('playerDropped', function()
    local src = source
    estadoTrabajoJugador[src] = nil
end)
