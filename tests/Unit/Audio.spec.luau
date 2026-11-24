--!strict
-- Señales de sonido (estructura sin audio) y SoundController con clases reales.
-- No hay audio aprobado: ninguna señal tiene assetId y nada suena. Para probar la
-- reproducción se usa un catálogo de PRUEBA con un id ficticio "test://…" que nunca llega
-- al juego (no es un rbxassetid).
local T = harness.T
local expect = T.expect
local AudioCues = harness.get("ReplicatedStorage.Shared.Config.AudioCues")
local Elements = harness.get("ReplicatedStorage.Shared.Config.Elements")
local Species = harness.get("ReplicatedStorage.Shared.Config.Species")
local roblox = harness.sandbox.roblox

T.describe("AudioCues · catálogo sin audio", function()
	T.it("todas las señales están pendientes, sin ID, y el orden las recoge una vez", function()
		local seen = {}
		for _, id in ipairs(AudioCues.Order) do
			expect(seen[id] == nil).toBe(true)
			seen[id] = true
			local c = AudioCues.ById[id]
			expect(c.id).toBe(id)
			expect(c.assetId == nil).toBe(true)
			expect(c.status).toBe("Pending")
			expect(c.volume > 0 and c.volume <= 1).toBe(true)
		end
		for id in pairs(AudioCues.ById) do
			expect(seen[id]).toBe(true)
		end
		expect(table.isfrozen(AudioCues.ById)).toBe(true)
	end)

	T.it("los ids siguen la convención y cubren elementos, combate, iniciales, biomas e interfaz", function()
		local C = AudioCues.ById
		for _, el in ipairs(Elements.Order) do
			for _, phase in ipairs({ "Cast", "Travel", "Impact" }) do
				expect(C["SFX_" .. el .. "_" .. phase] ~= nil).toBe(true)
			end
		end
		for _, ev in ipairs({
			"Hit",
			"Crit",
			"Shield",
			"Heal",
			"Burn",
			"Paralyze",
			"Stun",
			"Reflect",
			"Victory",
			"Defeat",
			"NexoCharge",
		}) do
			expect(C["SFX_Combat_" .. ev] ~= nil).toBe(true)
		end
		for _, sp in ipairs({ "kuachi", "xolumi", "teselo" }) do
			for _, a in ipairs({ "Idle", "Move", "Happy", "Hurt", "Attack", "Special", "Evolve", "Victory" }) do
				expect(C["SFX_CR_" .. sp .. "_" .. a].category).toBe("Creature")
			end
		end
		for biome in pairs(Species.Biomes) do
			expect(C["AMB_" .. biome .. "_Base"].loop).toBe(true)
			expect(C["MUS_" .. biome .. "_Explore"].category).toBe("Music")
			expect(C["MUS_" .. biome .. "_Battle"] ~= nil).toBe(true)
		end
		local patterns = {
			"^SFX_%u%l+_%u%l+$",
			"^SFX_Combat_%u%a+$",
			"^SFX_CR_%l+_%u%l+$",
			"^AMB_%u%a+_%u%l+$",
			"^MUS_%u%a+_%u%l+$",
			"^SFX_UI_%u%a+$",
		}
		for id in pairs(C) do
			local ok = false
			for _, p in ipairs(patterns) do
				if string.match(id, p) then
					ok = true
				end
			end
			if not ok then
				error("Id fuera de convención: " .. id)
			end
		end
		expect(C.SFX_UI_Tap ~= nil and C.SFX_UI_Evolve ~= nil).toBe(true)
		-- Los impactos de Config/VFX usan señales que existen
		local VFX = harness.get("ReplicatedStorage.Shared.Config.VFX")
		for _, imp in pairs(VFX.Impacts) do
			expect(C[imp.sound] ~= nil).toBe(true)
		end
	end)
end)

T.describe("SoundController (clases reales)", function()
	local function setup(cues: any?)
		harness.sandbox.resetCalls()
		local sb = harness.sandbox.newClient({})
		local SoundController = sb.load("StarterPlayerScripts.Client.Audio.SoundController")
		local Context = sb.load("StarterPlayerScripts.Client.VFX.VFXContext")
		local folder = roblox.Instance.new("Folder")
		Context.setRoot(folder)
		local clock = { t = 0 }
		local ctl = SoundController.new({
			cues = cues,
			now = function()
				return clock.t
			end,
			rng = {
				NextNumber = function(_, a: number, b: number): number
					return a + (b - a) * 0.8
				end,
			},
			maxVoices = 4,
			root = folder,
		})
		return ctl, clock, folder
	end

	T.it("con el catálogo real no suena nada ni se crea ningún Sound", function()
		local ctl, _, folder = setup(nil)
		for _, id in ipairs({
			"SFX_Fuego_Cast",
			"SFX_Combat_Hit",
			"SFX_CR_kuachi_Happy",
			"MUS_ValleCopal_Explore",
			"NoExiste",
		}) do
			expect(ctl:play(id, { at = roblox.Vector3.new(1, 2, 3) }) == nil).toBe(true)
		end
		expect(ctl:stats().voices).toBe(0)
		expect(ctl:stats().skipped).toBe(5)
		expect(#harness.sandbox.calls.play).toBe(0)
		expect(#folder:GetDescendants()).toBe(0)
	end)

	T.it("con audio (catálogo de prueba): espacial, variación de tono y pool de voces", function()
		local cues = {
			TEST_Spatial = {
				id = "TEST_Spatial",
				category = "Combat",
				assetId = "test://spatial",
				volume = 0.5,
				rollOffMaxDistance = 80,
				pitchVariance = 0.1,
				status = "Approved",
			},
			TEST_Ui = { id = "TEST_Ui", category = "UI", assetId = "test://ui", volume = 0.4, status = "Approved" },
		}
		local ctl, clock, folder = setup(cues)
		local s = ctl:play("TEST_Spatial", { at = roblox.Vector3.new(5, 1, -3) }) :: any
		expect(s ~= nil).toBe(true)
		expect(s.RollOffMaxDistance).toBe(80)
		expect(s.Parent:IsA("Attachment")).toBe(true)
		expect(math.abs(s.PlaybackSpeed - 1) <= 0.1 + 1e-6).toBe(true)
		expect(#harness.sandbox.calls.play).toBe(1)
		local ui = ctl:play("TEST_Ui") :: any
		expect(ui.Parent).toBe(folder) -- sin posición: sonido de interfaz
		-- Muchas reproducciones con el tiempo avanzando: nunca más de 4 voces, se reutilizan
		for i = 1, 30 do
			clock.t += if i % 3 == 0 then 4 else 0.1
			ctl:play("TEST_Spatial", { at = roblox.Vector3.new(i, 0, 0) })
		end
		expect(ctl:stats().voices <= 4).toBe(true)
		expect(ctl:stats().played).toBe(32)
		ctl:setCategoryVolume("Combat", 0.5)
		local quiet = ctl:play("TEST_Spatial", { at = roblox.Vector3.new(0, 0, 0) }) :: any
		expect(math.abs(quiet.Volume - 0.25) < 1e-6).toBe(true)
	end)
end)
