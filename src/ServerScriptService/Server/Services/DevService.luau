--!strict
-- Comandos de prueba (solo Studio o lista blanca de Config/Dev). Permiten acelerar la
-- progresión sin tocar el balance de producción. El contrato marca estas acciones
-- como devOnly y RemoteGateway las rechaza para cualquier otro jugador.

local Server = script.Parent.Parent
local PetRules = require(Server.Domain.PetRules)
local ProfileSchema = require(Server.Domain.ProfileSchema)
local DevGate = require(script.Parent.DevGate)

local DevService = {}

function DevService.init(deps: { data: any, gateway: any })
	local data = deps.data
	deps.gateway.register("Dev.GrantXp", function(player, amount: number)
		return data.run(player, function(p, ctx)
			local pet = p.companionPetId and p.pets[p.companionPetId]
			if not pet then
				return { ok = false, err = "NoCompanion" }
			end
			return { ok = true, data = PetRules.addXp(pet, amount, { now = ctx.now }) }
		end)
	end)
	deps.gateway.register("Dev.GrantCoins", function(player, amount: number)
		return data.run(player, function(p)
			p.currencies.Monedas += amount
			return { ok = true, data = { balance = p.currencies.Monedas } }
		end)
	end)
	deps.gateway.register("Dev.ResetProfile", function(player)
		if data.storeKind == "Production" then
			return { ok = false, err = "Forbidden" }
		end
		data.resetForDev(player, ProfileSchema.new(player.UserId, os.time()))
		data.pushProfile(player)
		return { ok = true }
	end)
end

-- Atajo: el atributo NexoDevBoost activa los multiplicadores de Config/Dev.
function DevService.setBoost(player: Player, enabled: boolean)
	if DevGate.isDev(player) then
		player:SetAttribute("NexoDevBoost", enabled)
	end
end

return DevService
