--!strict
-- Config/BiomeArt: estructura y rangos de la dirección de arte de los biomas.
-- Las reglas vienen de la Biblia visual (docs/ART_BIBLE_GENESIS.md §4 y §7) y de los
-- rangos que admite Roblox en Lighting, Atmosphere, Clouds y los efectos de posproceso.

local T = harness.T
local expect = T.expect
local BiomeArt = harness.get("ReplicatedStorage.Shared.Config.BiomeArt")
local Elements = harness.get("ReplicatedStorage.Shared.Config.Elements")
local Guardians = harness.get("ReplicatedStorage.Shared.Config.Guardians")
local World = harness.get("ReplicatedStorage.Shared.Config.World")

local BIOMES = { "ValleCopal", "MareaCoralina", "CumbreBrasa", "MesetaFulgor", "VeloAstral" }
local MOMENTS = { "Tarde", "Crepusculo", "Noche" }
local PIGMENT_MAX = 0.70 -- Genesis §4.1, regla 3 (saturación HSV)

-- Materiales de terreno de Roblox (Enum.Material que acepta Terrain).
local TERRAIN_MATERIALS = {}
for _, m in ipairs({
	"Asphalt",
	"Basalt",
	"Brick",
	"Cobblestone",
	"Concrete",
	"CrackedLava",
	"Glacier",
	"Grass",
	"Ground",
	"Ice",
	"LeafyGrass",
	"Limestone",
	"Mud",
	"Pavement",
	"Rock",
	"Salt",
	"Sand",
	"Sandstone",
	"Slate",
	"Snow",
	"WoodPlanks",
}) do
	TERRAIN_MATERIALS[m] = true
end

local function saturation(c: { number }): number
	local hi = math.max(c[1], c[2], c[3])
	local lo = math.min(c[1], c[2], c[3])
	if hi == 0 then
		return 0
	end
	return (hi - lo) / hi
end

local function checkColor(c: { number }, where: string)
	if #c ~= 3 then
		error(where .. ": el color debe tener 3 canales")
	end
	for _, v in ipairs(c) do
		if v ~= math.floor(v) or v < 0 or v > 255 then
			error(string.format("%s: canal fuera de 0-255 (%s)", where, tostring(v)))
		end
	end
end

local function inRange(v: number, lo: number, hi: number, where: string)
	if v < lo or v > hi then
		error(string.format("%s = %s fuera de [%s, %s]", where, tostring(v), tostring(lo), tostring(hi)))
	end
end

local function eachPreset(fn: (biome: string, moment: string, p: any) -> ())
	for _, id in ipairs(BIOMES) do
		for _, moment in ipairs(MOMENTS) do
			fn(id, moment, BiomeArt.ById[id].presets[moment])
		end
	end
end

T.describe("Dirección de arte de los biomas (Config/BiomeArt)", function()
	T.it("hay 5 biomas, en orden, con sus elementos, guardián y tres momentos de luz", function()
		expect(#BiomeArt.Order).toBe(5)
		local count = 0
		for _ in pairs(BiomeArt.ById) do
			count += 1
		end
		expect(count).toBe(5)
		for i, id in ipairs(BIOMES) do
			expect(BiomeArt.Order[i]).toBe(id)
			local b = BiomeArt.ById[id]
			expect(b.id).toBe(id)
			expect(#b.elements >= 3).toBe(true)
			for _, e in ipairs(b.elements) do
				expect(Elements.ById[e] ~= nil).toBe(true)
			end
			expect(#b.guardian > 0).toBe(true)
			expect(b.presets[b.defaultMoment] ~= nil).toBe(true)
			for _, moment in ipairs(MOMENTS) do
				expect(type(b.presets[moment].label)).toBe("string")
			end
		end
		expect(BiomeArt.ById.ValleCopal.guardian).toBe(Guardians.ById.copalia.name)
		-- Las puertas del Mirador apuntan a biomas que tienen dirección de arte
		for _, gate in ipairs(World.BiomeGates) do
			expect(BiomeArt.ById[gate.biome] ~= nil).toBe(true)
		end
	end)

	T.it("Lighting: ClockTime en [0, 24) y escalas de entorno y sombra en [0, 1]", function()
		eachPreset(function(id, moment, p)
			local L = p.Lighting
			local at = id .. "." .. moment .. ".Lighting"
			if not (L.clockTime >= 0 and L.clockTime < 24) then
				error(at .. ".clockTime fuera de [0, 24): " .. tostring(L.clockTime))
			end
			inRange(L.brightness, 0, 10, at .. ".brightness")
			inRange(L.geographicLatitude, -90, 90, at .. ".geographicLatitude")
			inRange(L.environmentDiffuseScale, 0, 1, at .. ".environmentDiffuseScale")
			inRange(L.environmentSpecularScale, 0, 1, at .. ".environmentSpecularScale")
			inRange(L.shadowSoftness, 0, 1, at .. ".shadowSoftness")
			inRange(L.exposureCompensation, -3, 3, at .. ".exposureCompensation")
			for _, key in ipairs({ "ambient", "outdoorAmbient", "colorShiftTop", "colorShiftBottom" }) do
				checkColor(L[key], at .. "." .. key)
			end
		end)
	end)

	T.it("densidades entre 0 y 1; la atmósfera en el rango de la Biblia visual (0,30–0,38)", function()
		eachPreset(function(id, moment, p)
			local at = id .. "." .. moment
			local A = p.Atmosphere
			inRange(A.density, 0, 1, at .. ".Atmosphere.density")
			inRange(A.density, 0.30, 0.38, at .. ".Atmosphere.density (Genesis §7)")
			inRange(A.offset, 0, 1, at .. ".Atmosphere.offset")
			inRange(A.glare, 0, 10, at .. ".Atmosphere.glare")
			inRange(A.haze, 0, 10, at .. ".Atmosphere.haze")
			checkColor(A.color, at .. ".Atmosphere.color")
			checkColor(A.decay, at .. ".Atmosphere.decay")
			inRange(p.Clouds.cover, 0, 1, at .. ".Clouds.cover")
			inRange(p.Clouds.density, 0, 1, at .. ".Clouds.density")
			checkColor(p.Clouds.color, at .. ".Clouds.color")
		end)
	end)

	T.it("posproceso con mesura: bloom ≤ 0,6 y umbral ≥ 0,9; contraste +0,05…+0,10; saturación ≈ 0", function()
		eachPreset(function(id, moment, p)
			local at = id .. "." .. moment
			inRange(p.Bloom.intensity, 0, 0.6, at .. ".Bloom.intensity")
			inRange(p.Bloom.threshold, 0.9, 4, at .. ".Bloom.threshold")
			inRange(p.Bloom.size, 0, 56, at .. ".Bloom.size")
			inRange(p.SunRays.intensity, 0, 0.15, at .. ".SunRays.intensity")
			inRange(p.SunRays.spread, 0, 1, at .. ".SunRays.spread")
			local cc = p.ColorCorrection
			inRange(cc.contrast, 0.05, 0.10, at .. ".ColorCorrection.contrast")
			inRange(cc.saturation, -0.1, 0.1, at .. ".ColorCorrection.saturation")
			inRange(cc.brightness, -0.1, 0.1, at .. ".ColorCorrection.brightness")
			checkColor(cc.tintColor, at .. ".ColorCorrection.tintColor")
		end)
	end)

	T.it("los pigmentos no pasan del 70 % de saturación (los emisivos y acentos van aparte)", function()
		for _, id in ipairs(BIOMES) do
			local b = BiomeArt.ById[id]
			expect(#b.palette >= 8).toBe(true)
			local pigments = 0
			for _, s in ipairs(b.palette) do
				if not string.match(s.hex, "^#%x%x%x%x%x%x$") then
					error(id .. "." .. s.id .. ": hex mal formado " .. s.hex)
				end
				checkColor(s.rgb, id .. "." .. s.id)
				expect(s.kind == "Pigmento" or s.kind == "Emisivo" or s.kind == "Acento").toBe(true)
				if s.kind == "Pigmento" then
					pigments += 1
					if saturation(s.rgb) > PIGMENT_MAX then
						error(string.format("%s.%s %s satura al %.0f %%", id, s.id, s.hex, saturation(s.rgb) * 100))
					end
				end
			end
			expect(pigments >= 6).toBe(true)
			for _, t in ipairs(b.terrain) do
				if saturation(t.rgb) > PIGMENT_MAX then
					error(string.format("%s terreno %s %s satura de más", id, t.material, t.hex))
				end
			end
			if saturation(b.water.color) > PIGMENT_MAX then
				error(id .. ": el agua satura de más")
			end
		end
	end)

	T.it("terreno: materiales válidos, variantes MAT_<Bioma>_ y ningún material base en dos biomas", function()
		local owner: { [string]: string } = {}
		for _, id in ipairs(BIOMES) do
			local b = BiomeArt.ById[id]
			expect(#b.terrain >= 3).toBe(true)
			for _, t in ipairs(b.terrain) do
				if not TERRAIN_MATERIALS[t.material] then
					error(id .. ": material de terreno inválido " .. t.material)
				end
				if not string.match(t.variant, "^MAT_" .. id .. "_%w+$") then
					error(id .. ": nombre de variante fuera de convención " .. t.variant)
				end
				if owner[t.material] then
					error(string.format("%s ya lo usa %s; no puede usarlo %s", t.material, owner[t.material], id))
				end
				owner[t.material] = id
			end
			local w = b.water
			checkColor(w.color, id .. ".water")
			inRange(w.transparency, 0, 1, id .. ".water.transparency")
			inRange(w.reflectance, 0, 1, id .. ".water.reflectance")
			inRange(w.waveSize, 0, 1, id .. ".water.waveSize")
			inRange(w.waveSpeed, 0, 100, id .. ".water.waveSpeed")
			checkColor(b.fogColor, id .. ".fogColor")
		end
	end)

	T.it("muestra ambiental de 120×120 con landmark dentro y presupuesto móvil (salvo el Valle)", function()
		for _, id in ipairs(BIOMES) do
			local s = BiomeArt.ById[id].sample
			if id == "ValleCopal" then
				expect(s).toBe(nil)
				continue
			end
			expect(s ~= nil).toBe(true)
			expect(s.plotSize[1]).toBe(120)
			expect(s.plotSize[2]).toBe(120)
			local lm = s.landmark
			expect(string.match(lm.id, "^WD_" .. id .. "_") ~= nil).toBe(true)
			for axis = 1, 3 do
				expect(lm.size[axis] > 0).toBe(true)
			end
			-- La huella del landmark cabe en la parcela
			expect(math.abs(lm.position[1]) + lm.size[1] / 2 <= 60).toBe(true)
			expect(math.abs(lm.position[3]) + lm.size[3] / 2 <= 60).toBe(true)
			expect(lm.visibleFrom >= 120).toBe(true)
			expect(#s.path >= 3).toBe(true)
			local b = s.budget
			-- Mismos topes que el Valle (World.spec) y 20 partículas/s por emisor (Biblia p. 26)
			expect(b.parts <= 500).toBe(true)
			expect(b.lights <= 12).toBe(true)
			expect(b.emitters <= 8).toBe(true)
			expect(b.particlesPerSecond <= b.emitters * 20).toBe(true)
			expect(b.terrainFills > 0).toBe(true)
		end
	end)

	T.it("transiciones y modificadores dentro de rango", function()
		local tr = BiomeArt.Transitions
		for _, key in ipairs({ "momentSeconds", "zoneSeconds", "combatInSeconds", "combatOutSeconds", "restoreSeconds" }) do
			inRange(tr[key], 0.1, 30, "Transitions." .. key)
		end
		local m = BiomeArt.Modifiers
		inRange(m.Combate.auraScale, 0.6, 0.6, "Modifiers.Combate.auraScale (Biblia p. 26)")
		inRange(m.JefeFase2.brightness, -0.2, 0, "Modifiers.JefeFase2.brightness")
		inRange(m.Rayo.maxFlashesPerSecond, 0, 3, "Modifiers.Rayo.maxFlashesPerSecond")
		inRange(m.Rayo.durationSeconds, 0, 0.1, "Modifiers.Rayo.durationSeconds")
		inRange(m.Cinematica.farIntensity, 0, 0.25, "Modifiers.Cinematica.farIntensity")
		expect(table.isfrozen(BiomeArt.ById.ValleCopal.presets.Tarde.Lighting)).toBe(true)
	end)
end)
