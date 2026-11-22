--!strict
-- Contrato cliente → servidor. Única puerta de entrada: RemoteFunction "NexoRequest".
-- El cliente SOLICITA acciones; el servidor valida tipo, frecuencia, secuencia,
-- proximidad y estado, y decide. Ningún argumento lleva cantidades, daño ni premios.
--
-- args: lista ordenada de validadores
--   { kind = "string", max = n } | { kind = "int", min = a, max = b } | { kind = "bool" }
-- rate: { burst, perSecond } (cubeta de fichas por jugador y acción)
-- near: ancla física que el servidor comprueba (World.luau) y radio en studs

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type ArgSpec = { kind: "string" | "int" | "bool", max: number?, min: number? }
export type ActionSpec = {
	args: { ArgSpec },
	rate: { burst: number, perSecond: number },
	near: string?,
	devOnly: boolean?,
}

local S = function(max: number): ArgSpec
	return { kind = "string", max = max }
end
local I = function(min: number, max: number): ArgSpec
	return { kind = "int", min = min, max = max }
end
local B: ArgSpec = { kind = "bool" }

local Actions: { [string]: ActionSpec } = {
	-- Sincronización: el cliente pide reenviar su vista al terminar de conectarse
	["Profile.Get"] = { args = {}, rate = { burst = 2, perSecond = 0.2 } },

	-- Onboarding
	["Onboarding.FinishIntro"] = { args = { B }, rate = { burst = 2, perSecond = 0.2 } },
	["Hatch.ChooseStarter"] = { args = { S(16) }, rate = { burst = 2, perSecond = 0.2 }, near = "StarterEggs" },
	["Hatch.Ack"] = { args = {}, rate = { burst = 3, perSecond = 0.5 } },

	-- Monstruos y cuidado
	["Pet.SetCompanion"] = { args = { S(32) }, rate = { burst = 4, perSecond = 1 } },
	["Pet.SetNickname"] = { args = { S(32), S(64) }, rate = { burst = 2, perSecond = 0.2 } },
	["Care.Feed"] = { args = { S(32), S(24) }, rate = { burst = 6, perSecond = 2 } },
	["Care.Play"] = { args = { S(32) }, rate = { burst = 4, perSecond = 1 } },
	["Pet.Evolve"] = { args = { S(32) }, rate = { burst = 2, perSecond = 0.5 } },

	-- Santuario (lugar físico: hay que estar en el propio lote)
	["Sanctuary.Visit"] = { args = {}, rate = { burst = 3, perSecond = 0.5 }, near = "PlayerLot" },
	["Sanctuary.Place"] = { args = { S(32), I(1, 4) }, rate = { burst = 6, perSecond = 2 }, near = "PlayerLot" },
	["Sanctuary.Remove"] = { args = { I(1, 4) }, rate = { burst = 6, perSecond = 2 }, near = "PlayerLot" },
	["Sanctuary.Collect"] = { args = {}, rate = { burst = 3, perSecond = 1 }, near = "PlayerLot" },

	-- Despensa del Gabinete
	["Shop.BuyFood"] = { args = { S(24), I(1, 10) }, rate = { burst = 5, perSecond = 1 }, near = "Despensa" },

	-- Combate PvE (el Opaco está en el mundo)
	-- Sin proximidad: el mapa del acto (Mirador o acceso rápido) abre cualquier etapa
	-- desbloqueada; el servidor valida requisitos, equipo y coste.
	["Battle.Start"] = { args = { S(32) }, rate = { burst = 2, perSecond = 0.5 } },
	["Battle.Act"] = { args = { S(64), I(1, 999), S(32) }, rate = { burst = 4, perSecond = 2 } },
	["Battle.Forfeit"] = { args = { S(64) }, rate = { burst = 2, perSecond = 0.5 } },

	-- Recompensas
	["Reward.Claim"] = { args = { S(96) }, rate = { burst = 4, perSecond = 1 } },

	-- Fase 2 · Criadero: huevos e incubadora (el servidor decide tiempos y resultado)
	["Egg.Incubate"] = { args = { S(32), I(1, 5) }, rate = { burst = 4, perSecond = 1 } },
	["Egg.Hatch"] = { args = { I(1, 5) }, rate = { burst = 4, perSecond = 1 } },
	["Incubator.BuySlot"] = { args = { I(1, 5) }, rate = { burst = 2, perSecond = 0.3 } },

	-- Fase 2 · Repisa de Cofres (contenido fijado al obtener el cofre)
	["Chest.Open"] = { args = { S(32) }, rate = { burst = 4, perSecond = 1 } },

	-- Fase 2 · Tablón de Encargos: el cliente solo pide reclamar; el progreso es del servidor
	["Quest.Claim"] = { args = { S(8), I(1, 3) }, rate = { burst = 4, perSecond = 1 } },

	-- Fase 2 · Aventura: acertijo del Tesoro y equipo (lista "id,id,id")
	["Adventure.Treasure"] = { args = { S(32), S(16) }, rate = { burst = 4, perSecond = 1 } },
	["Team.Set"] = { args = { S(110) }, rate = { burst = 4, perSecond = 1 } },

	-- Fase 2 · Santuario: decoración (en el propio lote), vitrina, Vivero y títulos
	["Sanctuary.PlaceDecor"] = {
		args = { I(1, 6), S(32) },
		rate = { burst = 6, perSecond = 2 },
		near = "PlayerLot",
	},
	["Sanctuary.ClearDecor"] = { args = { I(1, 6) }, rate = { burst = 6, perSecond = 2 }, near = "PlayerLot" },
	["Sanctuary.Template"] = { args = { S(16) }, rate = { burst = 2, perSecond = 0.5 }, near = "PlayerLot" },
	["Sanctuary.Showcase"] = { args = { S(110) }, rate = { burst = 4, perSecond = 1 } },
	["Sanctuary.Expand"] = { args = {}, rate = { burst = 2, perSecond = 0.3 } },
	["Title.Equip"] = { args = { S(32) }, rate = { burst = 4, perSecond = 1 } },

	-- Viaje rápido del menú del árbol (lleva a la estación; no la usa a distancia)
	["World.Travel"] = { args = { S(24) }, rate = { burst = 2, perSecond = 0.3 } },

	-- Solo Studio / lista blanca (Config/Dev)
	["Dev.GrantXp"] = { args = { I(1, 100000) }, rate = { burst = 5, perSecond = 2 }, devOnly = true },
	["Dev.GrantCoins"] = { args = { I(1, 100000) }, rate = { burst = 5, perSecond = 2 }, devOnly = true },
	["Dev.ResetProfile"] = { args = {}, rate = { burst = 1, perSecond = 0.1 }, devOnly = true },
}

-- Mensajes servidor → cliente por RemoteEvent "NexoPush"
local Push = {
	Profile = "Profile", -- vista completa del perfil (ProfileView)
	Toast = "Toast", -- aviso breve
	BattleStart = "BattleStart",
	BattleTurn = "BattleTurn",
	BattleEnd = "BattleEnd",
	Kicked = "Kicked",
}

return Freeze.deep({
	RemoteFolder = "NexoRemotes",
	RequestName = "NexoRequest",
	PushName = "NexoPush",
	Actions = Actions,
	Push = Push,
})
