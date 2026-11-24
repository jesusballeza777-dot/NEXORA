--!strict
-- Punto de entrada del cliente. Conecta red, estado, interfaz y mundo.
-- El cliente nunca decide resultados: muestra la vista que envía el servidor y
-- envía intenciones validadas en RemoteGateway.

-- El mundo se replica completo antes de "Loaded" (StreamingEnabled = false, D-019)
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Client = script.Parent:WaitForChild("Client")
local Net = require(Client.Net)
local State = require(Client.State)
local Hud = require(Client.UI.Hud)
local Kit = require(Client.UI.Kit)
local Modals = require(Client.UI.Modals)
local WorldController = require(Client.Controllers.WorldController)
local BattleController = require(Client.Controllers.BattleController)
local QuickMenu = require(Client.UI.QuickMenu)
local LotController = require(Client.Controllers.LotController)
local AmbientLifeController = require(Client.Controllers.AmbientLifeController)
local VFXContext = require(Client.VFX.VFXContext)
local VFXSettings = require(Client.VFX.VFXSettings)
local AuraController = require(Client.VFX.AuraController)
local Ceremony = require(Client.UI.Ceremony)
local Encounters = require(game:GetService("ReplicatedStorage").Shared.Config.Encounters)
local World = require(game:GetService("ReplicatedStorage").Shared.Config.World)
local Breeding = require(Client.UI.Screens.Breeding)
local Adventure = require(Client.UI.Screens.Adventure)

local introShown = false
local hatchShown = false
local lastStep: string? = nil
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
		QuickMenu.open(function()
			Modals.nexoMenu(Modals.reward)
		end, Modals.sanctuary)
	end,
})
local stations: { [string]: () -> () } = {
	Despensa = Modals.shop,
	Criadero = Breeding.incubator,
	Tablon = Breeding.quests,
	RepisaCofres = Breeding.chests,
	Mirador = Adventure.map,
}
WorldController.init({
	confirmEgg = Modals.confirmEgg,
	openNexo = function()
		Modals.nexoMenu(Modals.reward)
	end,
	openShop = Modals.shop,
	openStation = function(stationId: string?)
		local open = stationId and stations[stationId]
		if open then
			open()
		elseif stationId and World.Stations[stationId] then
			-- Estaciones que se presentan pero aún no abren (Portal de Arenas, Círculo)
			toast(World.Stations[stationId].label .. ": se abrirá más adelante")
		end
	end,
	openSanctuary = Modals.sanctuary,
	toast = toast,
})
BattleController.init({
	suspendWorld = WorldController.suspend,
	setHud = Hud.setVisible,
	showReward = Modals.reward,
	-- Resultado de etapa: estrellas y premios; luego la recompensa por reclamar
	showStageResult = function(payload)
		local enc = Encounters.ById[payload.encounterId]
		Ceremony.stageResult(enc.name, payload.result, function()
			if payload.result.rewardId then
				Modals.reward(payload.result.rewardId)
			end
		end)
	end,
	toast = toast,
	elementColor = Modals.ElementColor,
})

-- Aviso de logro: solo cuando el servidor marca uno nuevo entre dos vistas
local Achievements = require(game:GetService("ReplicatedStorage").Shared.Config.Achievements)
local knownAchievements: { [string]: boolean }? = nil
local function announceAchievements(view: any)
	local first = knownAchievements == nil
	local known: { [string]: boolean } = knownAchievements or {}
	for _, a in ipairs(view.achievements or {}) do
		if a.unlockedAt and not known[a.id] then
			known[a.id] = true
			local def = Achievements.ById[a.id]
			if not first and def then
				Hud.toast("🏅", "Logro: " .. def.name .. " · premio en el Gran Nexo")
			end
		end
	end
	knownAchievements = known
end

-- Reacciones del acompañante cuando sube de nivel o gana Vínculo
local function celebrate(view: any)
	for _, pet in ipairs(view.pets) do
		local before = lastPetsSnapshot[pet.id]
		if before and (pet.level > before.level or pet.bond > before.bond) and pet.isCompanion then
			WorldController.react(nil)
			if pet.level > before.level then
				Hud.toast("⬆", string.format("%s sube a nivel %d", Kit.escape(pet.name), pet.level))
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
	announceAchievements(view)
	local step = view.onboarding.step
	if step == "Intro" and lastStep ~= nil and lastStep ~= "Intro" then
		-- El perfil volvió a empezar (Dev.ResetProfile en Studio): repetir la bienvenida
		introShown, hatchShown = false, false
		table.clear(lastPetsSnapshot)
	end
	lastStep = step
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

-- Efectos: un solo paso por frame para todos (auras, combate, impactos)
VFXSettings.detect()
VFXContext.start(game:GetService("RunService").RenderStepped)
AuraController.start(VFXContext.runtime(), function()
	local camera = workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end)
WorldController.start()
LotController.start()
AmbientLifeController.start()
-- Oyentes listos: se pide la vista por si el primer envío llegó antes de conectarlos
Net.request("Profile.Get")
