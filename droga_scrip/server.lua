--[[ 
    🔥 Sistema de droga, este scrip solo funcionar con QBCore
    💻 Autor: El_tortilla1
    📅 Fecha: 2025-06-13
    🧠 Script de práctica - Prohibida su venta sin autorización
    📌 Discord: Tortilla Scripts
]]


print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("^2 Proyecto de practica - El_tortilla1")
print("^5 Propósito: Portafolio, no comercial")
print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━^7")

local QBCore = exports['qb-core']:GetCoreObject()

local plantsState = {}

local plants = {
    { coords = vector3(2222.0, 5576.0, 53.8), type = "amnesia" },
    { coords = vector3(2224.0, 5578.0, 53.8), type = "amnesia" },
    { coords = vector3(2226.0, 5580.0, 53.8), type = "amnesia" },
    { coords = vector3(2225.94, 5577.63, 53.74), type = "amnesia"},
    {coords = vector3(2228.62, 5575.53, 53.68), type = "amnesia"},
    {coords = vector3(2234.73, 5577.35, 53.92), type = "amnesia"}
}

for i = 1, #plants do
    plantsState[i] = true
end

RegisterNetEvent("droga_scrip:recogerPlanta", function(index)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not plants[index] or not plantsState[index] then
        TriggerClientEvent('QBCore:Notify', src, "Esta planta no está disponible.", "error")
        return
    end

    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local plantCoords = plants[index].coords

    if #(playerCoords - plantCoords) > 3.0 then
        TriggerClientEvent('QBCore:Notify', src, "Estás muy lejos de la planta.", "error")
        return
    end

    plantsState[index] = false

    local itemName = "weed_" .. plants[index].type
    Player.Functions.AddItem(itemName, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "add")
    TriggerClientEvent('QBCore:Notify', src, "Has recogido: " .. plants[index].type, "success")

    TriggerClientEvent("droga_scrip:removePlant", -1, index)

    SetTimeout(60000, function()
        plantsState[index] = true
        TriggerClientEvent("droga_scrip:respawnPlant", -1, index)
    end)
end)

RegisterNetEvent("droga_scrip:venderMarihuana", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local types = { "amnesia" }
    local total = 0

    for _, tipo in pairs(types) do
        local itemName = "weed_" .. tipo
        local item = Player.Functions.GetItemByName(itemName)
        if item then
            Player.Functions.RemoveItem(itemName, item.amount)
            total = total + (item.amount * 200)
        end
    end

    if total > 0 then
        Player.Functions.AddMoney("cash", total)
        TriggerClientEvent('QBCore:Notify', src, "Has vendido marihuana por $" .. total, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "No tienes marihuana para vender.", "error")
    end
end)

QBCore.Functions.CreateCallback('droga_scrip:getPlants', function(_, cb)
    cb(plants)
end)
