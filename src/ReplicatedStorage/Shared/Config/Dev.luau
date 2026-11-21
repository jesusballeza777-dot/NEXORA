--!strict
-- Configuración de desarrollador. NUNCA altera el balance de producción:
-- los multiplicadores solo se aplican cuando Server/Services/DevGate autoriza al
-- jugador, y eso solo ocurre en Studio (que usa el almacén de pruebas).

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	EnabledInStudio = true,
	-- Restringe los comandos de prueba de Studio a estos UserIds (vacío = todos en Studio).
	-- No tiene efecto en servidores publicados.
	AllowedUserIds = {},
	XpMultiplier = 10,
	CoinMultiplier = 5,
	SkipCooldowns = true,
	-- Nombre del DataStore de pruebas. Studio y pruebas NUNCA escriben en producción.
	TestDataStoreName = "NEXORA_Profiles_TEST_v1",
	ProductionDataStoreName = "NEXORA_Profiles_v1",
})
