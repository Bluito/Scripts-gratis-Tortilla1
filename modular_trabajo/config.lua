--[[ 
    🔥 Trabajo de entregar paquetes, este scrip solo funcionar con QBCore
    💻 Autor: El_tortilla1
    📅 Fecha: 2025-06-17
    🧠 Script de práctica - Prohibida su venta sin autorización
    📌 Discord: Tortilla scripts (BETA)
]]

Config = {}

Config.JobName = "Mensajero Express"

Config.NPC = {
    model = "s_m_m_postal_01",
    coords = vector3(884.411, -57.012, 77.8),
    heading = 80.0
}

Config.Car = {
    modelcar = "speedo",
    coordsCar = vector3(907.034, -60.061, 80.0),
    headingCar = 180.0
}

Config.Pickups = {
    vector3(-345.23, -875.14, 31.32),
    vector3(1200.54, -3115.82, 5.54),
    vector3(-1200.45, -1564.78, 4.62),
    vector3(310.50, -592.30, 43.28),
    vector3(984.20, -3000.50, 5.90),
    vector3(1100.4, -418.12, 67.15),
}

Config.Pagos = {
    base = 350
}

Config.EntregaNPC = {
    model = "s_m_m_dockwork_01" -- modelo para el NPC que recibe la caja
}
