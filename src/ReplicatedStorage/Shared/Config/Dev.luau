--!strict
-- Configuración de desarrollador. NUNCA altera el balance de producción:
-- los multiplicadores solo se aplican cuando Server/Services/DevGate autoriza al
-- jugador (Studio, o UserId en la lista blanca de un servidor privado de pruebas).

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	EnabledInStudio = true,
	-- UserIds con acceso a comandos de prueba en servidores en vivo (vacío por defecto).
	AllowedUserIds = {},
	XpMultiplier = 10,
	CoinMultiplier = 5,
	SkipCooldowns = true,
	-- Nombre del DataStore de pruebas. Studio y pruebas NUNCA escriben en producción.
	TestDataStoreName = "NEXORA_Profiles_TEST_v1",
	ProductionDataStoreName = "NEXORA_Profiles_v1",
})
