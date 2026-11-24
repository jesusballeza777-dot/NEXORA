--!strict
-- Mapa lógico de «huesos» y puntos de anclaje de una criatura, igual para:
-- * el BLOCKOUT de Parts (CreatureBuilder marca cada pieza con el atributo "Bone");
-- * el MODELO IMPORTADO (MeshCreature) con instancias Bone de los mismos nombres que
--   assets/Creatures/*/asset.json: root, spine/body, chest, neck, head, jaw, legF_L/R,
--   legB_L/R, legM_L/R, pawF_*, pawB_*, tail1..tail5 y, en Mitlaxis, ringA, ringB, skyDisc.
-- Convención de los activos: Y arriba, la criatura mira a +Z, +X es su izquierda (_L).
-- Todo en espacio del modelo (relativo a su raíz), ya escalado.

local CreatureRig = {}

export type BoneRec = {
	name: string,
	pivot: Vector3, -- articulación en reposo (espacio del modelo)
	parent: string?, -- hueso padre resuelto (nil = raíz)
	parts: { any }, -- PartRec del blockout
	instance: Instance?, -- Bone del modelo importado
}

export type Anchors = {
	center: Vector3, -- centro del torso
	bodyRadius: number, -- semieje horizontal mayor del torso
	height: number,
	faceZ: number, -- plano de la cara (lo más adelantado de la cabeza)
	head: Vector3,
	headRadius: number,
	back: Vector3, -- detrás del cuerpo (Z < 0): nace el aura
	ground: Vector3, -- a ras de suelo, detrás
	top: Vector3, -- detrás de la cabeza (halo)
	mouth: Vector3, -- delante de la cara (salen los ataques)
	above: Vector3, -- encima de la cabeza (estrellas de aturdido)
	feet: Vector3,
}

export type Rig = {
	kind: string, -- "Parts" | "Bones"
	bones: { [string]: BoneRec },
	order: { string }, -- padres antes que hijos
	torso: string,
	anchors: Anchors,
	primary: BasePart?, -- pieza a la que se cuelgan attachments del aura
	primaryOffset: CFrame, -- su CFrame respecto a la raíz del modelo
}

-- Padres candidatos de cada hueso (se toma el primero que exista)
local SPINE = { "chest", "spine", "body" }
local PARENTS: { [string]: { string } } = {
	spine = { "root" },
	body = { "root" },
	chest = { "spine", "body" },
	neck = SPINE,
	head = { "neck", "chest", "spine", "body" },
	jaw = { "head" },
	legF_L = SPINE,
	legF_R = SPINE,
	legM_L = { "spine", "body" },
	legM_R = { "spine", "body" },
	legB_L = { "spine", "body" },
	legB_R = { "spine", "body" },
	pawF_L = { "legF_L" },
	pawF_R = { "legF_R" },
	pawB_L = { "legB_L" },
	pawB_R = { "legB_R" },
	tail1 = { "spine", "body" },
	tail2 = { "tail1" },
	tail3 = { "tail2" },
	tail4 = { "tail3" },
	tail5 = { "tail4" },
	gill_L = { "head" },
	gill_R = { "head" },
	wing_L = SPINE,
	wing_R = SPINE,
	ringA = { "body", "spine" },
	ringB = { "body", "spine" },
	skyDisc = { "body", "spine" },
}
CreatureRig.Parents = PARENTS

local function resolveParent(name: string, bones: { [string]: any }): string?
	for _, candidate in ipairs(PARENTS[name] or SPINE) do
		if candidate == "root" then
			return nil
		end
		if bones[candidate] and candidate ~= name then
			return candidate
		end
	end
	return nil
end

local function order(bones: { [string]: BoneRec }): { string }
	local depth: { [string]: number } = {}
	local function d(name: string): number
		if depth[name] then
			return depth[name]
		end
		local p = bones[name].parent
		local v = if p and bones[p] then d(p) + 1 else 0
		depth[name] = v
		return v
	end
	local list = {}
	for name in pairs(bones) do
		d(name)
		table.insert(list, name)
	end
	table.sort(list, function(a, b)
		if depth[a] ~= depth[b] then
			return depth[a] < depth[b]
		end
		return a < b
	end)
	return list
end

-- Caja (en espacio del modelo) de un conjunto de piezas del blockout
local function box(recs: { any }): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, rec in ipairs(recs) do
		local cf: CFrame = rec.offset
		local s = rec.part.Size / 2
		local ext = Vector3.new(
			math.abs(cf.XVector.X) * s.X + math.abs(cf.YVector.X) * s.Y + math.abs(cf.ZVector.X) * s.Z,
			math.abs(cf.XVector.Y) * s.X + math.abs(cf.YVector.Y) * s.Y + math.abs(cf.ZVector.Y) * s.Z,
			math.abs(cf.XVector.Z) * s.X + math.abs(cf.YVector.Z) * s.Y + math.abs(cf.ZVector.Z) * s.Z
		)
		lo = lo:Min(cf.Position - ext)
		hi = hi:Max(cf.Position + ext)
	end
	return lo, hi
end

local function centroid(recs: { any }): Vector3
	local sum = Vector3.zero
	for _, rec in ipairs(recs) do
		sum += rec.offset.Position
	end
	return if #recs > 0 then sum / #recs else Vector3.zero
end

local function anchorsFrom(
	center: Vector3,
	torsoHalf: Vector3,
	_lo: Vector3,
	hi: Vector3,
	headLo: Vector3?,
	headHi: Vector3?,
	scale: number
): Anchors
	local hLo = headLo or Vector3.new(center.X - 0.3, hi.Y - 0.6, hi.Z - 0.6)
	local hHi = headHi or Vector3.new(center.X + 0.3, hi.Y, hi.Z)
	local head = (hLo + hHi) / 2
	local headHalf = (hHi - hLo) / 2
	local faceZ = hHi.Z
	local bodyRadius = math.max(torsoHalf.X, torsoHalf.Z, 0.4 * scale)
	local backZ = math.min(center.Z - torsoHalf.Z * 0.5, -0.1 * scale)
	return {
		center = center,
		bodyRadius = bodyRadius,
		height = hi.Y,
		faceZ = faceZ,
		head = head,
		headRadius = math.max(headHalf.X, headHalf.Y, headHalf.Z),
		back = Vector3.new(0, center.Y + torsoHalf.Y * 0.2, backZ),
		ground = Vector3.new(0, 0.15 * scale, math.min(center.Z - torsoHalf.Z * 0.3, -0.1 * scale)),
		top = Vector3.new(0, head.Y + headHalf.Y * 0.5, math.min(head.Z - headHalf.Z - 0.25 * scale, faceZ - 0.5)),
		mouth = Vector3.new(0, head.Y - headHalf.Y * 0.2, faceZ + 0.15 * scale),
		above = Vector3.new(0, hi.Y + 0.5 * scale, head.Z),
		feet = Vector3.new(center.X, 0.05, center.Z),
	}
end

-- Rig de un blockout de CreatureBuilder
function CreatureRig.fromParts(creature: any): Rig
	local groups: { [string]: { any } } = {}
	for _, rec in ipairs(creature.parts) do
		local name = rec.part:GetAttribute("Bone") or "spine"
		groups[name] = groups[name] or {}
		table.insert(groups[name], rec)
	end
	local torso = if groups.spine then "spine" elseif groups.body then "body" else "spine"
	local bones: { [string]: BoneRec } = {}
	for name, recs in pairs(groups) do
		if name ~= "root" then
			bones[name] = { name = name, pivot = Vector3.zero, parts = recs, parent = nil, instance = nil }
		end
	end
	for name, b in pairs(bones) do
		b.parent = resolveParent(name, bones)
	end
	local torsoRecs = groups[torso] or creature.parts
	local tLo, tHi = box(torsoRecs)
	local center = centroid(torsoRecs)
	-- Pivotes (articulaciones) a partir de la geometría de cada grupo
	for name, b in pairs(bones) do
		local c = centroid(b.parts)
		if name == torso or name == "chest" or name == "ringA" or name == "ringB" or name == "skyDisc" then
			b.pivot = c
		elseif name == "head" then
			local parentRecs = if b.parent and bones[b.parent] then bones[b.parent].parts else torsoRecs
			b.pivot = c:Lerp(centroid(parentRecs), 0.3)
		elseif name == "neck" then
			local lowest = b.parts[1].offset.Position
			for _, rec in ipairs(b.parts) do
				if rec.offset.Position.Y < lowest.Y then
					lowest = rec.offset.Position
				end
			end
			b.pivot = lowest
		elseif string.sub(name, 1, 3) == "leg" then
			local _, hi = box(b.parts)
			b.pivot = Vector3.new(c.X, hi.Y, c.Z)
		elseif string.sub(name, 1, 4) == "tail" then
			b.pivot = b.parts[1].offset.Position
		else
			-- Branquias y alas: la pieza más cercana al cuerpo
			local best, bestD = c, math.huge
			for _, rec in ipairs(b.parts) do
				local d = (rec.offset.Position - center).Magnitude
				if d < bestD then
					best, bestD = rec.offset.Position, d
				end
			end
			b.pivot = best
		end
	end
	local lo, hi = box(creature.parts)
	local headLo, headHi = nil, nil
	if bones.head then
		headLo, headHi = box(bones.head.parts)
	end
	local primaryRec = torsoRecs[1] or creature.parts[1]
	return {
		kind = "Parts",
		bones = bones,
		order = order(bones),
		torso = torso,
		anchors = anchorsFrom(center, (tHi - tLo) / 2, lo, hi, headLo, headHi, creature.scale or 1),
		primary = primaryRec and primaryRec.part,
		primaryOffset = if primaryRec then primaryRec.offset else CFrame.identity,
	}
end

-- CFrame de un Bone en espacio del mundo usando solo CFrame (sirve también en Lune)
local function boneWorld(bone: Instance): CFrame
	local parent = bone.Parent
	local own = (bone :: any).CFrame :: CFrame
	if parent and parent:IsA("Bone") then
		return boneWorld(parent) * own
	elseif parent and parent:IsA("BasePart") then
		return (parent :: BasePart).CFrame * own
	end
	return own
end

-- Rig de un modelo importado con huesos (Bone) nombrados como en asset.json.
-- Hay que verificarlo en Studio con el modelo real (orientación de los huesos en reposo).
function CreatureRig.fromBones(model: Model, scale: number?): Rig
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	local rootCF = if root then root.CFrame else CFrame.identity
	local bones: { [string]: BoneRec } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Bone") and d.Name ~= "root" then
			local pivot = rootCF:PointToObjectSpace(boneWorld(d).Position)
			bones[d.Name] = { name = d.Name, pivot = pivot, parts = {}, parent = nil, instance = d }
		end
	end
	for name, b in pairs(bones) do
		b.parent = resolveParent(name, bones)
	end
	local torso = if bones.spine then "spine" elseif bones.body then "body" else "spine"
	local center = if bones[torso] then bones[torso].pivot else Vector3.new(0, 1, 0)
	local size = Vector3.new(2, 2, 2)
	pcall(function()
		size = model:GetExtentsSize()
	end)
	local s = scale or 1
	local half = size / 2
	local headPos = if bones.head then bones.head.pivot else Vector3.new(0, size.Y * 0.8, half.Z)
	local r = math.max(0.3 * s, half.X * 0.4)
	return {
		kind = "Bones",
		bones = bones,
		order = order(bones),
		torso = torso,
		anchors = anchorsFrom(
			center,
			Vector3.new(half.X * 0.8, center.Y * 0.6, half.Z * 0.5),
			Vector3.new(-half.X, 0, -half.Z),
			Vector3.new(half.X, size.Y, half.Z),
			headPos - Vector3.new(r, r, r),
			headPos + Vector3.new(r, r, r),
			s
		),
		primary = root,
		primaryOffset = CFrame.identity,
	}
end

-- Rig cacheado por criatura (la tabla Creature no se toca)
local cache: { [any]: Rig } = setmetatable({}, { __mode = "k" }) :: any
function CreatureRig.get(creature: any): Rig
	local rig = cache[creature]
	if not rig then
		rig = CreatureRig.fromParts(creature)
		cache[creature] = rig
	end
	return rig
end

-- Convierte un punto del espacio del modelo al espacio de la pieza primaria (Attachment.CFrame)
function CreatureRig.toPrimary(rig: Rig, modelPos: Vector3): CFrame
	return rig.primaryOffset:Inverse() * CFrame.new(modelPos)
end

return CreatureRig
