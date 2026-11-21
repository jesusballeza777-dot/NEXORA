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
	["Battle.Start"] = { args = { S(32) }, rate = { burst = 2, perSecond = 0.5 }, near = "Encounter" },
	["Battle.Act"] = { args = { S(64), I(1, 999), S(32) }, rate = { burst = 4, perSecond = 2 } },
	["Battle.Forfeit"] = { args = { S(64) }, rate = { burst = 2, perSecond = 0.5 } },

	-- Recompensas
	["Reward.Claim"] = { args = { S(96) }, rate = { burst = 4, perSecond = 1 } },

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
