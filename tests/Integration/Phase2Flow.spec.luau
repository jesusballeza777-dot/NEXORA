--!strict
-- Fase 2 de punta a punta con el código del servidor: migración 1→2, huevos e
-- incubadora con reconexión, cofres idempotentes, encargos con rotación, santuario y el
-- Acto I completo hasta Copalia.
local T = harness.T
local expect = T.expect
local Play = harness.require("./Play")(harness)
local Actions = harness.get("ServerScriptService.Server.Domain.Actions")
local ProfileSchema = harness.get("ServerScriptService.Server.Domain.ProfileSchema")
local ProfileStore = harness.get("ServerScriptService.Server.Persistence.ProfileStore")
local MemoryBackend = harness.get("ServerScriptService.Server.Persistence.MemoryBackend")
local PetRules = harness.get("ServerScriptService.Server.Domain.PetRules")
local EggRules = harness.get("ServerScriptService.Server.Domain.EggRules")
local ChestRules = harness.get("ServerScriptService.Server.Domain.ChestRules")
local QuestRules = harness.get("ServerScriptService.Server.Domain.QuestRules")
local EncounterRules = harness.get("ServerScriptService.Server.Domain.EncounterRules")
local CollectionRules = harness.get("ServerScriptService.Server.Domain.CollectionRules")
local ProfileView = harness.get("ServerScriptService.Server.Domain.ProfileView")
local AchievementRules = harness.get("ServerScriptService.Server.Domain.AchievementRules")
local Achievements = harness.get("ReplicatedStorage.Shared.Config.Achievements")
local Encounters = harness.get("ReplicatedStorage.Shared.Config.Encounters")
local Incubation = harness.get("ReplicatedStorage.Shared.Config.Incubation")

-- Equipo fuerte para recorrer el acto sin depender del azar (3 Tallados nivel 22)
local function strongTeam(p: any, starterId: string): { string }
	Play.boost(p, starterId, 22, "Tallado")
	local ids = { starterId }
	for _, sp in ipairs({ "zunzi", "kuachi" }) do
		local r = PetRules.create(p, sp, { kind = "Dev", at = Play.now })
		local id = r.data.petId
		Play.boost(p, id, 22, "Tallado")
		table.insert(ids, id)
	end
	expect(Actions.setTeam(p, ids, Play.ctx()).ok).toBe(true)
	return ids
end

local function claimAll(p: any)
	local ids = {}
	for id in pairs(p.rewards.pending) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local r = Actions.claimReward(p, id, Play.ctx())
		assert(r.ok, "no se pudo reclamar " .. id .. ": " .. tostring(r.err))
	end
end

local function correctAnswer(enc: any): string
	local ElementChart = harness.get("ReplicatedStorage.Shared.Domain.ElementChart")
	for _, el in ipairs(enc.riddle.options) do
		if ElementChart.classify(ElementChart.multiplier(el, { enc.riddle.sealElement }, false)) == "Strong" then
			return el
		end
	end
	error("acertijo sin respuesta")
end

T.describe("Fase 2 · migración del perfil 1 → 2", function()
	T.it("un perfil de la Fase 1 conserva todo y gana colección y estrellas", function()
		local p = Play.tutorialProfile(900, "EggBarro")
		local r = Play.encounter(p, "valle_r1_e1", "M1", 31)
		expect(r.ok).toBe(true)
		claimAll(p)
		-- Simular la forma v1: sin secciones de la Fase 2
		local legacy: any = p
		for _, k in ipairs({
			"collection",
			"eggs",
			"nextEggSerial",
			"incubators",
			"chests",
			"nextChestSerial",
			"history",
			"quests",
			"codex",
			"decor",
			"showcase",
			"titles",
			"frames",
			"guardians",
			"achievements",
		}) do
			legacy[k] = nil
		end
		legacy.story = { cleared = legacy.story.cleared, repeatDay = 0, repeatCount = 0 }
		legacy.schemaVersion = 1
		local monedas = legacy.currencies.Monedas
		local migrated = ProfileSchema.migrate(legacy, Play.now)
		expect(migrated.schemaVersion).toBe(ProfileSchema.CURRENT_VERSION)
		expect(migrated.currencies.Monedas).toBe(monedas)
		expect(migrated.collection.xolumi.broteAt ~= nil).toBe(true) -- su inicial
		expect(migrated.collection.comalu.restoredAt ~= nil).toBe(true) -- Opaco vencido
		expect(migrated.story.stars.valle_r1_e1).toEqual({ true, false, false })
		expect(#migrated.incubators).toBe(Incubation.MaxSlots)
		expect(migrated.incubators[1].unlocked).toBe(true)
		expect(migrated.incubators[2].unlocked).toBe(false)
		expect(ProfileSchema.validate(migrated)).toBe(true)
	end)
end)

T.describe("Fase 2 · huevos e incubadora", function()
	T.it("la especie se fija al obtener el huevo y el tiempo corre desconectado", function()
		local backend = MemoryBackend.new()
		local store = ProfileStore.new({
			backend = backend,
			jobId = "srv-A",
			clock = function()
				return Play.now
			end,
		})
		local session = assert(store:load(901))
		local p = session.data
		-- Perfil del almacén: hacer el tutorial sobre él
		Actions.onLoad(p, Play.ctx())
		Actions.finishIntro(p, true, Play.ctx())
		Actions.chooseStarter(p, "EggGreca", Play.ctx())
		local g = EggRules.grant(p, "vainas", { kind = "Test", at = Play.now }, Play.now)
		expect(g.ok).toBe(true)
		local eggId = g.data.eggId
		expect(p.eggs[eggId].speciesId).toBe("vainas")
		expect(Actions.startIncubation(p, eggId, 1, Play.ctx()).ok).toBe(true)
		expect(Actions.hatchEgg(p, 1, Play.ctx()).err).toBe("NotReady")
		-- Desconexión: se guarda y se libera; pasan 6 minutos; vuelve a otro servidor
		assert(store:saveWithRetry(session, true))
		Play.advance(6 * 60)
		local store2 = ProfileStore.new({
			backend = backend,
			jobId = "srv-B",
			clock = function()
				return Play.now
			end,
		})
		local s2 = assert(store2:load(901))
		local p2 = s2.data
		local view = ProfileView.build(p2, Play.now)
		expect(view.incubators[1].ready).toBe(true)
		local h = Actions.hatchEgg(p2, 1, Play.ctx())
		expect(h.ok).toBe(true)
		expect(h.data.speciesId).toBe("vainas")
		expect(h.data.newSpecies).toBe(true)
		expect(p2.pets[h.data.petId].acquired.kind).toBe("Egg")
		expect(p2.collection.vainas.broteAt ~= nil).toBe(true)
		expect(p2.incubators[1].eggId).toBe(nil)
		-- La eclosión no se repite
		expect(Actions.hatchEgg(p2, 1, Play.ctx()).err).toBe("SlotEmpty")
		expect(ProfileSchema.validate(p2)).toBe(true)
	end)
	T.it("con el Vivero lleno el huevo espera listo: nada se pierde", function()
		local p = Play.tutorialProfile(902)
		p.inventoryCapacity = PetRules.inventoryUsed(p)
		local g = EggRules.grant(p, "zunzi", { kind = "Test", at = Play.now }, Play.now)
		Actions.startIncubation(p, g.data.eggId, 1, Play.ctx())
		Play.advance(400)
		expect(Actions.hatchEgg(p, 1, Play.ctx()).err).toBe("InventoryFull")
		expect(p.eggs[g.data.eggId] ~= nil).toBe(true)
		expect(p.incubators[1].eggId).toBe(g.data.eggId)
	end)
	T.it("ranuras: la 2.ª llega jugando, la 3.ª cuesta Monedas y la 4.ª no está en la beta", function()
		local p = Play.tutorialProfile(903)
		expect(Actions.buyIncubatorSlot(p, 2, Play.ctx()).err).toBe("NotPurchasable")
		expect(Actions.buyIncubatorSlot(p, 3, Play.ctx()).err).toBe("PreviousSlotLocked")
		expect(Actions.buyIncubatorSlot(p, 4, Play.ctx()).err).toBe("NotAvailable")
		local g = EggRules.grant(p, "zunzi", { kind = "Test", at = Play.now }, Play.now)
		expect(Actions.startIncubation(p, g.data.eggId, 2, Play.ctx()).err).toBe("SlotLocked")
	end)
end)

T.describe("Fase 2 · cofres", function()
	T.it("el contenido se fija al obtenerlo y se abre una sola vez", function()
		local p = Play.tutorialProfile(904)
		local g = ChestRules.grant(p, "Madera", { kind = "Test", at = Play.now }, Play.now)
		expect(g.ok).toBe(true)
		local chestId = g.data.chestId
		local fixedSpecies = p.chests[chestId].contents.eggs[1].speciesId
		expect(fixedSpecies).toBe("barrock") -- primera del grupo que el jugador no tiene
		local monedas = p.currencies.Monedas
		local opened = Actions.openChest(p, chestId, Play.ctx())
		expect(opened.ok).toBe(true)
		expect(p.currencies.Monedas).toBe(monedas + 300)
		expect(p.eggs[opened.data.eggIds[1]].speciesId).toBe(fixedSpecies)
		expect(Actions.openChest(p, chestId, Play.ctx()).err).toBe("ChestNotFound")
		expect(p.currencies.Monedas).toBe(monedas + 300)
		-- Un segundo cofre ya no repite la especie pendiente
		local g2 = ChestRules.grant(p, "Madera", { kind = "Test", at = Play.now }, Play.now)
		expect(p.chests[g2.data.chestId].contents.eggs[1].speciesId).toBe("vainas")
	end)
	T.it("sin espacio para el huevo el cofre no se abre ni se pierde", function()
		local p = Play.tutorialProfile(905)
		for _ = 1, Incubation.EggStorageCapacity do
			EggRules.grant(p, "zunzi", { kind = "Test", at = Play.now }, Play.now)
		end
		local g = ChestRules.grant(p, "Madera", { kind = "Test", at = Play.now }, Play.now)
		expect(Actions.openChest(p, g.data.chestId, Play.ctx()).err).toBe("EggStorageFull")
		expect(p.chests[g.data.chestId] ~= nil).toBe(true)
	end)
	T.it("los cofres de otra cuenta no existen para este jugador", function()
		local a = Play.tutorialProfile(906)
		local b = Play.tutorialProfile(907)
		local g = ChestRules.grant(a, "Plata", { kind = "Test", at = Play.now }, Play.now)
		expect(Actions.openChest(b, g.data.chestId, Play.ctx()).err).toBe("ChestNotFound")
		expect(a.chests[g.data.chestId] ~= nil).toBe(true)
	end)
end)

T.describe("Fase 2 · Tablón de Encargos", function()
	T.it("rotación determinista por día, con reinicio al día siguiente", function()
		local p = Play.tutorialProfile(908)
		QuestRules.refresh(p, Play.now)
		local first = {}
		for _, q in ipairs(p.quests.daily) do
			table.insert(first, q.questId)
		end
		expect(#first).toBe(3)
		-- Mismo día: no cambia aunque se refresque muchas veces
		QuestRules.refresh(p, Play.now + 3600)
		for i, q in ipairs(p.quests.daily) do
			expect(q.questId).toBe(first[i])
		end
		local day = p.quests.day
		Play.advance(86400)
		QuestRules.refresh(p, Play.now)
		expect(p.quests.day).toBe(day + 1)
		expect(p.quests.dailyBonusClaimed).toBe(false)
	end)
	T.it("el progreso llega por eventos del servidor y los tres diarios dan un Cofre de Madera", function()
		local p, petId = Play.tutorialProfile(909)
		QuestRules.refresh(p, Play.now)
		-- Forzar un tablón conocido para la prueba
		p.quests.daily = {
			{ questId = "D_Feed4", progress = 0, target = 4, coins = 150, claimed = false },
			{ questId = "D_Play3", progress = 0, target = 3, coins = 150, claimed = false },
			{ questId = "D_Collect2", progress = 0, target = 2, coins = 150, claimed = false },
		}
		p.items.RacionBasica = 10
		expect(Actions.claimQuest(p, "Daily", 1, Play.ctx()).err).toBe("QuestNotComplete")
		for _ = 1, 4 do
			Actions.feed(p, petId, "RacionBasica", Play.ctx())
		end
		for _ = 1, 3 do
			Play.advance(60)
			Actions.play(p, petId, Play.ctx())
		end
		QuestRules.track(p, "CollectCoins", 2, Play.now)
		local monedas = p.currencies.Monedas
		expect(Actions.claimQuest(p, "Daily", 1, Play.ctx()).ok).toBe(true)
		expect(Actions.claimQuest(p, "Daily", 1, Play.ctx()).err).toBe("AlreadyClaimed")
		expect(Actions.claimQuest(p, "Daily", 2, Play.ctx()).data.chestType).toBe(nil)
		local last = Actions.claimQuest(p, "Daily", 3, Play.ctx())
		expect(last.data.chestType).toBe("Madera")
		expect(p.currencies.Monedas).toBe(monedas + 450)
		expect(ChestRules.count(p)).toBe(1)
	end)
end)

T.describe("Fase 2 · Acto I completo", function()
	T.it("de la Linde a Copalia: estrellas, tesoros, regiones, secretas y jefe", function()
		local p, starter = Play.tutorialProfile(910, "EggBrasa")
		local team = strongTeam(p, starter)
		expect(#team).toBe(3)
		local seed = 100
		local function playStage(id: string)
			local enc = Encounters.ById[id]
			if enc.stageType == "Tesoro" then
				local wrong = nil
				for _, el in ipairs(enc.riddle.options) do
					if el ~= correctAnswer(enc) then
						wrong = el
					end
				end
				local miss = Actions.solveTreasure(p, id, wrong, Play.ctx())
				expect(miss.ok).toBe(true)
				expect(miss.data.solved).toBe(false)
				local hit = Actions.solveTreasure(p, id, correctAnswer(enc), Play.ctx())
				expect(hit.data.solved).toBe(true)
				expect(hit.data.stars[2]).toBe(true) -- segundo intento: ★★
				expect(hit.data.stars[3]).toBe(false) -- el reto era al primer intento
			else
				seed += 1
				local r, won = Play.encounter(p, id, "A" .. seed, seed)
				expect(won).toBe(true)
				expect(r.ok).toBe(true)
			end
			claimAll(p)
		end
		-- Las secretas siguen cerradas sin las 3 estrellas de la región
		for _, region in ipairs(Encounters.Regions) do
			for _, id in ipairs(region.stages) do
				playStage(id)
			end
			expect(EncounterRules.isUnlocked(p, region.secret)).toBe(EncounterRules.regionAllStars(p, region.index))
			expect(p.story.regionRewards[region.id .. ":clear"] ~= nil).toBe(true)
			expect(p.codex[region.clearCodex] ~= nil).toBe(true)
			expect((p.decor.owned[region.clearDecor] or 0) >= 1).toBe(true)
		end
		-- La 2.ª ranura se abrió al terminar la Región 1
		expect(p.incubators[2].unlocked).toBe(true)
		-- Jefe
		expect(EncounterRules.isUnlocked(p, "valle_boss")).toBe(true)
		playStage("valle_boss")
		expect(p.guardians.copalia ~= nil).toBe(true)
		expect(p.unlocks.ActoI_Completo ~= nil).toBe(true)
		local nexo = nil
		for id, chest in pairs(p.chests) do
			if chest.chestType == "Nexo" then
				nexo = id
			end
		end
		expect(nexo ~= nil).toBe(true)
		local opened = Actions.openChest(p, nexo, Play.ctx())
		expect(opened.ok).toBe(true)
		expect(p.codex["guardian:copalia"] ~= nil).toBe(true)
		-- Bestiario: los Opacos vencidos quedan registrados como restaurados
		for _, sp in ipairs({ "barrock", "vainas", "zunzi", "pabilo", "lumbro", "dienton" }) do
			expect(CollectionRules.bestiaryTier(p.collection[sp]) >= 2).toBe(true)
		end
		-- Logros que llegan solos al recorrer el acto (D-033)
		for _, id in ipairs({ "curiosidad", "niebla_disipada", "naturalista", "cielo_de_copal", "raiz_restaurada" }) do
			expect(p.achievements[id] ~= nil).toBe(true)
		end
		claimAll(p)
		expect(p.titles.owned["Amigo de Copalia"] ~= nil).toBe(true)
		expect(ProfileSchema.validate(p)).toBe(true)
	end)
	T.it("las 3 estrellas de una región dan Cofre de Oro y abren la secreta", function()
		local p, starter = Play.tutorialProfile(911, "EggBrasa")
		strongTeam(p, starter)
		-- Tres etapas superadas con estrellas perfectas (como si ya las tuviera)
		for _, id in ipairs({ "valle_r1_e1", "valle_r1_e2", "valle_r1_e3" }) do
			p.story.cleared[id] = { firstClearAt = Play.now, wins = 1 }
			p.story.stars[id] = { true, true, true }
		end
		-- El Tesoro al primer intento da ★★★ y completa la región
		local enc = Encounters.ById.valle_r1_e4
		local r = Actions.solveTreasure(p, "valle_r1_e4", correctAnswer(enc), Play.ctx())
		expect(r.data.stars).toEqual({ true, true, true })
		expect(r.data.regionStars).toBe(1)
		local chests = p.rewards.pending[r.data.rewardId].chests
		expect(table.find(chests, "Oro") ~= nil).toBe(true)
		expect(table.find(chests, "Plata") ~= nil).toBe(true)
		expect(EncounterRules.isUnlocked(p, "valle_r1_secret")).toBe(true)
	end)
	T.it("repetir da el 25 % y respeta el tope diario; un resultado no se aplica dos veces", function()
		local p, starter = Play.tutorialProfile(912, "EggBrasa")
		strongTeam(p, starter)
		local first = Play.encounter(p, "valle_r1_e1", "R0", 7)
		expect(first.data.firstClear).toBe(true)
		claimAll(p)
		local again = Play.encounter(p, "valle_r1_e1", "R1", 8)
		local reward = p.rewards.pending[again.data.rewardId]
		expect(reward.currencies.Monedas).toBe(50) -- 25 % de 200
		expect(reward.chests).toBe(nil)
		local dup = Actions.finishEncounter(p, "valle_r1_e1", "R1", true, 3, { starter }, Play.ctx())
		expect(dup.err).toBe("ResultAlreadyApplied")
	end)
	T.it("el rescate da el huevo de su especie según una tirada reproducible del 10 %", function()
		local hits = 0
		for i = 1, 200 do
			local p = ProfileSchema.new(5000 + i, Play.now)
			p.story.cleared.valle_r1_e4 = { firstClearAt = Play.now, wins = 1 }
			local rewardId = "battle:RS" .. i
			local enc = Encounters.ById.valle_r2_e5
			local r = EncounterRules.applyResult(
				p,
				"valle_r2_e5",
				"RS" .. i,
				true,
				{},
				Play.ctx(),
				"Defeat",
				{ turns = 5, faints = 0, elements = {}, rootsCut = 0, teamSize = 1 }
			)
			expect(r.ok).toBe(true)
			local eggs = p.rewards.pending[rewardId].eggs
			if eggs then
				expect(eggs[1]).toBe(enc.rescue.speciesId)
				hits += 1
			end
		end
		-- 10 % ± margen: la tirada es real pero reproducible por id de combate
		expect(hits >= 8 and hits <= 35).toBe(true)
	end)
end)

T.describe("Fase 2 · santuario", function()
	T.it("decoración solo con objetos propios; plantillas; vitrina; ampliar el Vivero", function()
		local p, petId = Play.tutorialProfile(913)
		expect(Actions.placeDecor(p, 1, "FarolDeCopal", Play.ctx()).err).toBe("DecorNotOwned")
		p.decor.owned.FarolDeCopal = 1
		expect(Actions.placeDecor(p, 1, "FarolDeCopal", Play.ctx()).ok).toBe(true)
		expect(Actions.placeDecor(p, 2, "FarolDeCopal", Play.ctx()).err).toBe("DecorNotOwned") -- una copia
		expect(Actions.placeDecor(p, 7, "FarolDeCopal", Play.ctx()).err).toBe("BadSlot")
		p.decor.owned.EstandarteDePapelPicado = 1
		expect(Actions.applyDecorTemplate(p, "Fiesta", Play.ctx()).ok).toBe(true)
		expect(Actions.setShowcase(p, { petId }, Play.ctx()).ok).toBe(true)
		expect(Actions.setShowcase(p, { "U1-999" }, Play.ctx()).err).toBe("PetNotOwned")
		p.currencies.Monedas = 5000
		local cap = p.inventoryCapacity
		expect(Actions.expandInventory(p, Play.ctx()).ok).toBe(true)
		expect(p.inventoryCapacity).toBe(cap + 10)
		expect(Actions.expandInventory(p, Play.ctx()).err).toBe("NotEnoughMonedas")
		expect(ProfileSchema.validate(p)).toBe(true)
	end)
	T.it("el equipo solo admite monstruos propios, sin repetir y hasta 3", function()
		local p, petId = Play.tutorialProfile(914)
		expect(Actions.setTeam(p, { petId, petId }, Play.ctx()).err).toBe("DuplicatePet")
		expect(Actions.setTeam(p, { "U914-99" }, Play.ctx()).err).toBe("PetNotOwned")
		expect(Actions.setTeam(p, {}, Play.ctx()).err).toBe("BadTeamSize")
		expect(Actions.setTeam(p, { petId }, Play.ctx()).ok).toBe(true)
	end)
end)

T.describe("Fase 2 · logros", function()
	T.it("se cumplen por eventos del servidor y su premio se reclama una sola vez", function()
		local p = Play.tutorialProfile(920)
		expect(p.achievements.primer_latido).toBe(nil)
		local g = EggRules.grant(p, "pabilo", { kind = "Test", at = Play.now }, Play.now)
		Actions.startIncubation(p, g.data.eggId, 1, Play.ctx())
		Play.advance(Incubation.SecondsByRarity.Comun + 1)
		local h = Actions.hatchEgg(p, 1, Play.ctx())
		expect(h.ok).toBe(true)
		expect(table.find(h.data.achievements, "primer_latido") ~= nil).toBe(true)
		expect(p.counters.eggsHatched).toBe(1)
		local rewardId = AchievementRules.rewardId("primer_latido")
		local pending = p.rewards.pending[rewardId]
		expect(pending.source.kind).toBe("Achievement")
		expect(pending.chests).toEqual({ "Madera" })
		local gems = p.currencies.Gemas
		expect(Actions.claimReward(p, rewardId, Play.ctx()).ok).toBe(true)
		expect(p.currencies.Gemas).toBe(gems + Achievements.GemsPerAchievement)
		expect(Actions.claimReward(p, rewardId, Play.ctx()).ok).toBe(false)
		-- Volver a entrar no lo repite
		local again = Actions.onLoad(p, Play.ctx())
		expect(#again.data.achievements).toBe(0)
		expect(p.rewards.pending[rewardId]).toBe(nil)
		-- La vista muestra el progreso acotado a la meta
		local view = ProfileView.build(p, Play.now)
		expect(#view.achievements).toBe(#Achievements.Order)
		for _, a in ipairs(view.achievements) do
			expect(a.progress <= a.goal).toBe(true)
			if a.id == "primer_latido" then
				expect(a.unlockedAt ~= nil).toBe(true)
				expect(a.rewardPending).toBe(false)
			end
		end
	end)
	T.it("migración 2 → 3: un perfil que ya cumplía la meta recibe el premio al entrar, una vez", function()
		local p, starter = Play.tutorialProfile(921)
		Play.boost(p, starter, 20)
		p.pets[starter].bond = 40
		local evolved = Actions.evolve(p, starter, Play.ctx())
		expect(evolved.ok).toBe(true)
		expect(table.find(evolved.data.achievements, "primer_tallado") ~= nil).toBe(true)
		-- Simular una cuenta guardada en la v2: sin logros, sin contador, sin premio
		local legacy = p
		legacy.achievements = nil
		legacy.counters.eggsHatched = nil
		legacy.rewards.pending[AchievementRules.rewardId("primer_tallado")] = nil
		legacy.schemaVersion = 2
		local migrated = ProfileSchema.migrate(legacy, Play.now)
		expect(migrated.schemaVersion).toBe(ProfileSchema.CURRENT_VERSION)
		expect(migrated.counters.eggsHatched).toBe(0) -- el inicial no nació en la incubadora
		expect(next(migrated.achievements)).toBe(nil)
		local r = Actions.onLoad(migrated, Play.ctx())
		expect(table.find(r.data.achievements, "primer_tallado") ~= nil).toBe(true)
		local rewardId = AchievementRules.rewardId("primer_tallado")
		expect(Actions.claimReward(migrated, rewardId, Play.ctx()).ok).toBe(true)
		expect(migrated.titles.owned.Tallador ~= nil).toBe(true)
		-- Si se perdiera la marca, el libro de recompensas impide un segundo premio
		migrated.achievements.primer_tallado = nil
		local gems = migrated.currencies.Gemas
		Actions.onLoad(migrated, Play.ctx())
		expect(migrated.achievements.primer_tallado ~= nil).toBe(true)
		expect(migrated.rewards.pending[rewardId]).toBe(nil)
		expect(migrated.currencies.Gemas).toBe(gems)
		expect(ProfileSchema.validate(migrated)).toBe(true)
	end)
end)
