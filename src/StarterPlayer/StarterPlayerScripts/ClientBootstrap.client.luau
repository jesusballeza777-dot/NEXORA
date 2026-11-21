--!strict
-- Punto de entrada del cliente. Conecta red, estado, interfaz y mundo.
-- El cliente nunca decide resultados: muestra la vista que envía el servidor y
-- envía intenciones validadas en RemoteGateway.

local Client = script.Parent:WaitForChild("Client")
local Net = require(Client.Net)
local State = require(Client.State)
local Hud = require(Client.UI.Hud)
local Modals = require(Client.UI.Modals)
local WorldController = require(Client.Controllers.WorldController)
local BattleController = require(Client.Controllers.BattleController)

local introShown = false
local hatchShown = false
local lastPetsSnapshot: { [string]: { level: number, bond: number } } = {}

local function toast(text: string)
	Hud.toast("•", text)
end

Modals.init(Hud)
Hud.init({
	openPet = function()
		Modals.petSheet(nil)
	end,
	openSanctuary = Modals.sanctuary,
	openNexo = function()
		Modals.nexoMenu(Modals.reward)
	end,
})
WorldController.init({
	confirmEgg = Modals.confirmEgg,
	openNexo = function()
		Modals.nexoMenu(Modals.reward)
	end,
	openShop = Modals.shop,
	openSanctuary = Modals.sanctuary,
	toast = toast,
})
BattleController.init({
	suspendWorld = WorldController.suspend,
	setHud = Hud.setVisible,
	showReward = Modals.reward,
	toast = toast,
	elementColor = Modals.ElementColor,
})

-- Reacciones del acompañante cuando sube de nivel o gana Vínculo
local function celebrate(view: any)
	for _, pet in ipairs(view.pets) do
		local before = lastPetsSnapshot[pet.id]
		if before and (pet.level > before.level or pet.bond > before.bond) and pet.isCompanion then
			WorldController.react(nil)
			if pet.level > before.level then
				Hud.toast("⬆", string.format("%s sube a nivel %d", pet.name, pet.level))
			end
		end
		lastPetsSnapshot[pet.id] = { level = pet.level, bond = pet.bond }
	end
end

Net.on("Profile", function(view)
	State.set(view)
	Hud.render(view)
	WorldController.applyState(view)
	celebrate(view)
	local step = view.onboarding.step
	if step == "Intro" and not introShown then
		introShown = true
		Hud.setVisible(false)
		Modals.intro(function(skipped)
			Net.request("Onboarding.FinishIntro", skipped)
			Hud.setVisible(true)
			Hud.toast("🥚", "Tres huevos de copal laten junto al Gran Nexo.")
		end)
	elseif step ~= "Intro" and not introShown then
		introShown = true
		Hud.setVisible(true)
	end
	if step == "Hatch" and not hatchShown then
		hatchShown = true
		local pet = State.pet(view.companionPetId)
		if pet then
			Modals.hatchReveal(pet)
		end
	end
end)
Net.on("Toast", function(payload)
	Hud.toast(payload.kind or "•", payload.text)
end)

WorldController.start()
