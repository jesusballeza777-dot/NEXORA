--!strict
-- Criaturas con malla importada (Fase 3).
--
-- En una experiencia publicada los scripts no pueden asignar las texturas de
-- SurfaceAppearance ni el MeshId de un MeshPart. Por eso la integración es:
--   1. En Studio, File → Import 3D con el GLB de assets/Creatures/... (mapas PBR en
--      SurfaceAppearance, huesos incluidos).
--   2. El Model resultante se guarda en ReplicatedStorage.CreatureModels con el nombre del
--      id del activo (p. ej. "CR_Kuachi_Brote_v01") y, si se quiere versionar, como
--      .rbxm en el repositorio.
--   3. Este módulo lo clona. Si no existe, devuelve nil y CreatureBuilder usa el blockout.
-- Nada de esto inventa IDs: si el modelo no está en el lugar, simplemente no se usa.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local CreatureAssets = require(Config:WaitForChild("CreatureAssets"))

local MeshCreature = {}

-- Activo registrado para una especie y forma (aunque aún no esté importado).
function MeshCreature.asset(speciesId: string, form: string): CreatureAssets.CreatureAsset?
	return CreatureAssets.ById[speciesId .. ":" .. form]
end

-- Plantilla importada en el lugar, si existe.
function MeshCreature.template(speciesId: string, form: string): Model?
	local a = MeshCreature.asset(speciesId, form)
	if not a then
		return nil
	end
	local folder = ReplicatedStorage:FindFirstChild("CreatureModels")
	if not folder then
		return nil
	end
	local m = folder:FindFirstChild(a.id)
	if m and m:IsA("Model") then
		return m
	end
	return nil
end

-- Clona la malla importada con una escala dada. Devuelve nil si no hay plantilla.
-- La escala usa Model:ScaleTo, que también escala los huesos.
function MeshCreature.build(speciesId: string, form: string, scale: number?): Model?
	local template = MeshCreature.template(speciesId, form)
	if not template then
		return nil
	end
	local model = template:Clone()
	model:SetAttribute("AssetId", (MeshCreature.asset(speciesId, form) :: any).id)
	model:SetAttribute("AssetStatus", (MeshCreature.asset(speciesId, form) :: any).status)
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CastShadow = true
			d.Massless = true
		end
	end
	return model
end

return MeshCreature
