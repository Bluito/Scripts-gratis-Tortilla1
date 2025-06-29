--[[ 
    🔥 Trabajo de entregar paquetes, este scrip solo funcionar con QBCore
    💻 Autor: El_tortilla1
    📅 Fecha: 2025-06-17
    🧠 Script de práctica - Prohibida su venta sin autorización
    📌 Discord: Tortilla scripts (BETA)
]]

print(Config.NPC.model) -- para probar si está cargado

print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("^2 Proyecto de practica - El_tortilla1")
print("^5 Propósito: Portafolio, no comercial")
print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━^7")

local QBCore = exports['qb-core']:GetCoreObject()

-- Estado activo por jugador: source -> { delivery = vector3, recogido = boolean, npc = entity }
local trabajoActivo = {}

-- Iniciar trabajo
RegisterNetEvent("Inicio", function()
    local src = source
    if trabajoActivo[src] then
        TriggerClientEvent("QBCore:Notify", src, "Ya tienes un trabajo activo.", "error")
        return
    end

    local zones = Config.Deliveries or Config.Pickups
    if not zones or #zones == 0 then
        TriggerClientEvent("QBCore:Notify", src, "No hay zonas disponibles.", "error")
        return
    end

    math.randomseed(os.time() + src) -- asegurar aleatoriedad única por jugador
    local delivery = zones[math.random(#zones)]
    trabajoActivo[src] = { delivery = delivery, recogido = false, npc = nil }
    TriggerClientEvent("cliente:IniciarTrabajo", src, delivery)
end)

-- Validar recogida
RegisterNetEvent("script:validarRecogida", function(pos)
    local src = source
    local data = trabajoActivo[src]
    if not data then
        TriggerClientEvent("QBCore:Notify", src, "No tienes un trabajo activo.", "error")
        return
    end
    if data.recogido then
        TriggerClientEvent("QBCore:Notify", src, "Ya has recogido la caja.", "error")
        return
    end
    if #(vector3(pos.x, pos.y, pos.z) - vector3(data.delivery.x, data.delivery.y, data.delivery.z)) > 20.0 then
        TriggerClientEvent("QBCore:Notify", src, "No estás lo suficientemente cerca de la zona.", "error")
        return
    end

    data.recogido = true
    TriggerClientEvent("cliente:paqueteRecogido", src)
end)

-- Validar entrega
RegisterNetEvent("script:validarEntrega", function(pos)
    local src = source
    local data = trabajoActivo[src]
    if not data or not data.recogido then
        TriggerClientEvent("QBCore:Notify", src, "No puedes entregar todavía.", "error")
        return
    end
    if #(vector3(pos.x, pos.y, pos.z) - vector3(data.delivery.x, data.delivery.y, data.delivery.z)) > 7.0 then
        TriggerClientEvent("QBCore:Notify", src, "No estás en la zona de entrega.", "error")
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    TriggerClientEvent("cliente:TrabajoTerminado", src, true)
    TriggerClientEvent("QBCore:Notify", src, "Entrega completada.", "success")
    Player.Functions.AddMoney("cash", Config.Pagos.base or 350, "Pago por entrega")
    trabajoActivo[src] = nil
end)

-- Comando para cancelar
QBCore.Commands.Add("terminartrabajo", "Cancelar trabajo de entrega", {}, false, function(src)
    if trabajoActivo[src] then
        trabajoActivo[src] = nil
        TriggerClientEvent("cliente:TrabajoTerminado", src, false)
        TriggerClientEvent("QBCore:Notify", src, "Trabajo cancelado.", "success")
    else
        TriggerClientEvent("QBCore:Notify", src, "No tienes trabajo activo.", "error")
    end
end)