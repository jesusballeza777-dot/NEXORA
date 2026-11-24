--!strict
-- Activos 3D de criaturas (Fase 3): el registro generado (Config/CreatureAssets) coincide con
-- los archivos de assets/, respeta los presupuestos de la Biblia (p. 120) y no declara IDs ni
-- aprobaciones que no existen.
local T = harness.T
local expect = T.expect
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local CreatureAssets = harness.get("ReplicatedStorage.Shared.Config.CreatureAssets")
local Species = harness.get("ReplicatedStorage.Shared.Config.Species")

local STATUSES = { Blockout = true, Proposal = true, InReview = true, Approved = true, Final = true }

local function geoMean(size: { number }): number
	return (size[1] * size[2] * size[3]) ^ (1 / 3)
end

T.describe("Activos 3D de los iniciales", function()
	T.it("están los seis: Brote y Tallado de Kuachi, Xolumi y Teselo", function()
		for _, sp in ipairs({ "kuachi", "xolumi", "teselo" }) do
			for _, form in ipairs({ "Brote", "Tallado" }) do
				local a = CreatureAssets.ById[sp .. ":" .. form]
				expect(a ~= nil).toBe(true)
				expect(Species.ById[a.species] ~= nil).toBe(true)
			end
		end
	end)

	T.it("cada activo tiene sus archivos y coincide con su asset.json", function()
		for _, key in ipairs(CreatureAssets.Order) do
			local a = CreatureAssets.ById[key]
			expect(fs.isFile(a.glb)).toBe(true)
			local meta = serde.decode("json", fs.readFile(a.folder .. "/asset.json"))
			expect(meta.id).toBe(a.id)
			expect(meta.lods.LOD0.triangles).toBe(a.triangles)
			for _, map in pairs(meta.maps) do
				expect(fs.isFile(a.folder .. "/" .. map)).toBe(true)
			end
			expect(fs.isFile(a.folder .. "/" .. meta.files.glbLod1)).toBe(true)
			expect(fs.isFile(a.folder .. "/" .. meta.files.obj)).toBe(true)
			-- cabecera glTF binaria
			expect(string.sub(fs.readFile(a.glb), 1, 4)).toBe("glTF")
		end
	end)

	T.it("respetan el presupuesto de triángulos y huesos de la Biblia (p. 120)", function()
		for _, key in ipairs(CreatureAssets.Order) do
			local a = CreatureAssets.ById[key]
			expect(a.triangles >= a.triangleBudget[1]).toBe(true)
			expect(a.triangles <= a.triangleBudget[2]).toBe(true)
			expect(a.bones <= a.boneBudget).toBe(true)
			expect(a.texture).toBe("1024x1024")
		end
	end)

	T.it("el Tallado crece ×1,4–×1,95 del Brote (media geométrica de la caja, rasgos firma incluidos)", function()
		for _, sp in ipairs({ "kuachi", "xolumi", "teselo" }) do
			local b = CreatureAssets.ById[sp .. ":Brote"]
			local t = CreatureAssets.ById[sp .. ":Tallado"]
			local ratio = (geoMean(t.sizeStuds) / geoMean(b.sizeStuds))
			expect(ratio >= 1.4 and ratio <= 1.95).toBe(true)
			-- el Tallado es más alto que el Brote
			expect(t.sizeStuds[2] > b.sizeStuds[2] * 1.3).toBe(true)
			-- escala del Brote junto a un avatar de 5 studs (Biblia visual §2): altura 1,2–2,4, largo ≤ 3,2
			expect(b.sizeStuds[2] >= 1.2 and b.sizeStuds[2] <= 2.4).toBe(true)
			expect(b.sizeStuds[3] <= 3.2).toBe(true)
		end
	end)

	T.it("nadie se aprueba solo: sin ID real no hay estado Final, y los IDs tienen forma válida", function()
		for _, key in ipairs(CreatureAssets.Order) do
			local a = CreatureAssets.ById[key]
			expect(STATUSES[a.status]).toBe(true)
			if a.status == "Final" then
				expect(a.roblox.meshAsset ~= nil).toBe(true)
			end
			if a.roblox.meshAsset then
				expect(string.match(a.roblox.meshAsset, "^rbxassetid://%d+$") ~= nil).toBe(true)
			end
			-- los activos de esta fase son propuestas: ninguno llega aprobado desde el código
			expect(a.status == "Approved" or a.status == "Final").toBe(false)
		end
	end)
end)
