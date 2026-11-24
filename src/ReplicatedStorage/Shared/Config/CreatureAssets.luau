--!strict
-- Registro de activos 3D de criaturas (Fase 3). GENERADO por tools/sculpt/registry.py
-- a partir de assets/Creatures/**/asset.json: no se edita a mano.
-- * status: Blockout | Proposal | InReview | Approved | Final (Biblia visual §11). Solo
--   una persona pasa un activo a Approved o Final.
-- * roblox: IDs reales tras importar en Studio. Mientras estén vacíos, CreatureBuilder
--   sigue usando el blockout de Parts (Config/Visuals). No se inventan IDs.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type RobloxRefs = {
	meshAsset: string?,
	colorMap: string?,
	normalMap: string?,
	roughnessMap: string?,
	metalnessMap: string?,
}

export type CreatureAsset = {
	id: string,
	species: string,
	form: string,
	status: string,
	folder: string,
	glb: string,
	triangles: number,
	triangleBudget: { number },
	bones: number,
	boneBudget: number,
	sizeStuds: { number },
	texture: string,
	roblox: RobloxRefs,
}

local ById: { [string]: CreatureAsset } = {
	["kuachi:Tallado"] = {
		id = "CR_Ascuacho_Tallado_v01",
		species = "kuachi",
		form = "Tallado",
		status = "Proposal",
		folder = "assets/Creatures/Initials/Ascuacho",
		glb = "assets/Creatures/Initials/Ascuacho/CR_Ascuacho_Tallado_v01.glb",
		triangles = 6108,
		triangleBudget = { 4000, 6500 },
		bones = 19,
		boneBudget = 30,
		sizeStuds = { 1.221, 2.61, 4.619 },
		texture = "1024x1024",
		roblox = {},
	},
	["kuachi:Brote"] = {
		id = "CR_Kuachi_Brote_v01",
		species = "kuachi",
		form = "Brote",
		status = "Proposal",
		folder = "assets/Creatures/Initials/Kuachi",
		glb = "assets/Creatures/Initials/Kuachi/CR_Kuachi_Brote_v01.glb",
		triangles = 3757,
		triangleBudget = { 2500, 4000 },
		bones = 12,
		boneBudget = 18,
		sizeStuds = { 0.974, 1.68, 2.329 },
		texture = "1024x1024",
		roblox = {},
	},
	["teselo:Tallado"] = {
		id = "CR_Mitlaxis_Tallado_v01",
		species = "teselo",
		form = "Tallado",
		status = "Proposal",
		folder = "assets/Creatures/Initials/Mitlaxis",
		glb = "assets/Creatures/Initials/Mitlaxis/CR_Mitlaxis_Tallado_v01.glb",
		triangles = 6108,
		triangleBudget = { 4000, 6500 },
		bones = 12,
		boneBudget = 30,
		sizeStuds = { 4.477, 3.479, 4.817 },
		texture = "1024x1024",
		roblox = {},
	},
	["teselo:Brote"] = {
		id = "CR_Teselo_Brote_v01",
		species = "teselo",
		form = "Brote",
		status = "Proposal",
		folder = "assets/Creatures/Initials/Teselo",
		glb = "assets/Creatures/Initials/Teselo/CR_Teselo_Brote_v01.glb",
		triangles = 3754,
		triangleBudget = { 2500, 4000 },
		bones = 8,
		boneBudget = 18,
		sizeStuds = { 1.983, 1.771, 3.184 },
		texture = "1024x1024",
		roblox = {},
	},
	["xolumi:Tallado"] = {
		id = "CR_Xolossus_Tallado_v01",
		species = "xolumi",
		form = "Tallado",
		status = "Proposal",
		folder = "assets/Creatures/Initials/Xolossus",
		glb = "assets/Creatures/Initials/Xolossus/CR_Xolossus_Tallado_v01.glb",
		triangles = 6104,
		triangleBudget = { 4000, 6500 },
		bones = 14,
		boneBudget = 30,
		sizeStuds = { 2.567, 2.951, 4.438 },
		texture = "1024x1024",
		roblox = {},
	},
	["xolumi:Brote"] = {
		id = "CR_Xolumi_Brote_v01",
		species = "xolumi",
		form = "Brote",
		status = "Proposal",
		folder = "assets/Creatures/Initials/Xolumi",
		glb = "assets/Creatures/Initials/Xolumi/CR_Xolumi_Brote_v01.glb",
		triangles = 3758,
		triangleBudget = { 2500, 4000 },
		bones = 9,
		boneBudget = 18,
		sizeStuds = { 1.805, 1.262, 2.478 },
		texture = "1024x1024",
		roblox = {},
	},
}

return Freeze.deep({
	ById = ById,
	Order = {
		"kuachi:Tallado",
		"kuachi:Brote",
		"teselo:Tallado",
		"teselo:Brote",
		"xolumi:Tallado",
		"xolumi:Brote",
	},
})
