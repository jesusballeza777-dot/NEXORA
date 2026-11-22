--!strict
-- Registra las acciones de onboarding, eclosión, cuidado, santuario, tienda,
-- recompensas y viaje. Cada manejador es una línea que delega en Domain/Actions:
-- la validación genérica ya la hizo RemoteGateway; aquí solo queda la lógica
-- específica de Roblox (filtrado de texto, notificaciones).
--
-- Agrupa HatchService, PetService, InventoryService/SanctuaryService, ShopService y
-- RewardService del documento de arquitectura: comparten dependencias y ningún
-- manejador supera unas pocas líneas, así que separarlos añadiría ceremonia sin valor.

local TextService = game:GetService("TextService")

local Server = script.Parent.Parent
local Actions = require(Server.Domain.Actions)
local ProfileView = require(Server.Domain.ProfileView)

local GameplayService = {}

local data: any
local world: any

local function run(player: Player, fn: (any, any) -> any)
	local result = data.run(player, fn)
	local session = data.get(player)
	if session then
		world.publish(player, ProfileView.build(session.data, os.time()))
	end
	return result
end

-- Lista "id,id,id" del cliente (máximo 3 ids no vacíos); el dominio valida propiedad.
local function splitIds(list: string): { string }?
	local ids = {}
	for id in string.gmatch(list, "[^,]+") do
		if #ids >= 3 or #id > 32 then
			return nil
		end
		table.insert(ids, id)
	end
	return ids
end

-- Filtra un apodo con TextService. Si el filtro falla, se rechaza (nunca se guarda sin filtrar).
local function filterNickname(player: Player, raw: string): string?
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(raw, player.UserId, Enum.TextFilterContext.PublicChat)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if not ok or type(filtered) ~= "string" then
		return nil
	end
	return filtered
end

function GameplayService.init(deps: { data: any, world: any, gateway: any })
	data = deps.data
	world = deps.world
	local gateway = deps.gateway

	-- Reenvía la vista del perfil (el cliente la pide cuando ya escucha los mensajes)
	gateway.register("Profile.Get", function(player)
		data.pushProfile(player)
		return { ok = true }
	end)

	gateway.register("Onboarding.FinishIntro", function(player, skipped: boolean)
		return run(player, function(p, ctx)
			return Actions.finishIntro(p, skipped, ctx)
		end)
	end)
	gateway.register("Hatch.ChooseStarter", function(player, eggId: string)
		return run(player, function(p, ctx)
			return Actions.chooseStarter(p, eggId, ctx)
		end)
	end)
	gateway.register("Hatch.Ack", function(player)
		return run(player, function(p, ctx)
			return Actions.ackHatch(p, ctx)
		end)
	end)

	gateway.register("Pet.SetCompanion", function(player, petId: string)
		return run(player, function(p, ctx)
			return Actions.setCompanion(p, petId, ctx)
		end)
	end)
	gateway.register("Pet.SetNickname", function(player, petId: string, raw: string)
		local filtered = filterNickname(player, raw)
		if filtered == nil then
			return { ok = false, err = "FilterUnavailable" }
		end
		return run(player, function(p, ctx)
			return Actions.setNickname(p, petId, filtered, ctx)
		end)
	end)
	gateway.register("Care.Feed", function(player, petId: string, foodId: string)
		return run(player, function(p, ctx)
			return Actions.feed(p, petId, foodId, ctx)
		end)
	end)
	gateway.register("Care.Play", function(player, petId: string)
		return run(player, function(p, ctx)
			return Actions.play(p, petId, ctx)
		end)
	end)
	gateway.register("Pet.Evolve", function(player, petId: string)
		return run(player, function(p, ctx)
			return Actions.evolve(p, petId, ctx)
		end)
	end)

	gateway.register("Sanctuary.Visit", function(player)
		return run(player, function(p, ctx)
			return Actions.visitHome(p, ctx)
		end)
	end)
	gateway.register("Sanctuary.Place", function(player, petId: string, slot: number)
		return run(player, function(p, ctx)
			return Actions.place(p, petId, slot, ctx)
		end)
	end)
	gateway.register("Sanctuary.Remove", function(player, slot: number)
		return run(player, function(p, ctx)
			return Actions.remove(p, slot, ctx)
		end)
	end)
	gateway.register("Sanctuary.Collect", function(player)
		return run(player, function(p, ctx)
			return Actions.collect(p, ctx)
		end)
	end)

	gateway.register("Shop.BuyFood", function(player, foodId: string, quantity: number)
		return run(player, function(p, ctx)
			return Actions.buyFood(p, foodId, quantity, ctx)
		end)
	end)

	gateway.register("Reward.Claim", function(player, rewardId: string)
		return run(player, function(p, ctx)
			return Actions.claimReward(p, rewardId, ctx)
		end)
	end)

	gateway.register("World.Travel", function(player, destination: string)
		return world.travel(player, destination)
	end)

	-- ===================== Fase 2 =====================
	gateway.register("Egg.Incubate", function(player, eggId: string, slot: number)
		return run(player, function(p, ctx)
			return Actions.startIncubation(p, eggId, slot, ctx)
		end)
	end)
	gateway.register("Egg.Hatch", function(player, slot: number)
		return run(player, function(p, ctx)
			return Actions.hatchEgg(p, slot, ctx)
		end)
	end)
	gateway.register("Incubator.BuySlot", function(player, slot: number)
		return run(player, function(p, ctx)
			return Actions.buyIncubatorSlot(p, slot, ctx)
		end)
	end)
	gateway.register("Chest.Open", function(player, chestId: string)
		return run(player, function(p, ctx)
			return Actions.openChest(p, chestId, ctx)
		end)
	end)
	gateway.register("Quest.Claim", function(player, kind: string, index: number)
		if kind ~= "Daily" and kind ~= "Weekly" then
			return { ok = false, err = "UnknownQuest" }
		end
		return run(player, function(p, ctx)
			return Actions.claimQuest(p, kind, index, ctx)
		end)
	end)
	gateway.register("Adventure.Treasure", function(player, stageId: string, element: string)
		return run(player, function(p, ctx)
			return Actions.solveTreasure(p, stageId, element, ctx)
		end)
	end)
	gateway.register("Team.Set", function(player, list: string)
		local ids = splitIds(list)
		if not ids then
			return { ok = false, err = "BadTeamSize" }
		end
		return run(player, function(p, ctx)
			return Actions.setTeam(p, ids, ctx)
		end)
	end)
	gateway.register("Sanctuary.PlaceDecor", function(player, slot: number, decorId: string)
		return run(player, function(p, ctx)
			return Actions.placeDecor(p, slot, decorId, ctx)
		end)
	end)
	gateway.register("Sanctuary.ClearDecor", function(player, slot: number)
		return run(player, function(p, ctx)
			return Actions.placeDecor(p, slot, nil, ctx)
		end)
	end)
	gateway.register("Sanctuary.Template", function(player, templateId: string)
		return run(player, function(p, ctx)
			return Actions.applyDecorTemplate(p, templateId, ctx)
		end)
	end)
	gateway.register("Sanctuary.Showcase", function(player, list: string)
		local ids = splitIds(list)
		if not ids then
			return { ok = false, err = "TooManyPets" }
		end
		return run(player, function(p, ctx)
			return Actions.setShowcase(p, ids, ctx)
		end)
	end)
	gateway.register("Sanctuary.Expand", function(player)
		return run(player, function(p, ctx)
			return Actions.expandInventory(p, ctx)
		end)
	end)
	gateway.register("Title.Equip", function(player, titleId: string)
		return run(player, function(p, ctx)
			return Actions.equipTitle(p, if titleId == "none" then nil else titleId, ctx)
		end)
	end)
end

return GameplayService
