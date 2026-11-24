--!strict
-- Piezas compartidas por todos los controladores de efectos del cliente: un pool, un
-- runtime (un solo paso por frame) y un ancla invisible en el origen para colgar los
-- attachments de efectos en coordenadas del mundo. Se crean al primer uso.

local VFXPool = require(script.Parent.VFXPool)
local VFXRuntime = require(script.Parent.VFXRuntime)

local VFXContext = {}

local pool: any = nil
local runtime: any = nil
local anchor: BasePart? = nil
local root: Instance? = nil

function VFXContext.pool(): any
	if not pool then
		pool = VFXPool.new()
	end
	return pool
end

function VFXContext.runtime(): any
	if not runtime then
		runtime = VFXRuntime.new()
	end
	return runtime
end

-- Dónde cuelgan los efectos del mundo (Workspace por defecto; las pruebas pasan una carpeta)
function VFXContext.setRoot(r: Instance)
	root = r
	if anchor then
		anchor.Parent = r
	end
end

-- Pieza invisible y anclada en el origen: un Attachment hijo suyo tiene CFrame = mundo
function VFXContext.anchor(): BasePart
	if not anchor or not anchor.Parent then
		local p = Instance.new("Part")
		p.Name = "NexoVFXAnchor"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.CFrame = CFrame.identity
		p.Parent = root or workspace
		anchor = p
	end
	return anchor :: BasePart
end

-- Conecta el runtime a la señal por frame (lo llama ClientBootstrap una vez)
function VFXContext.start(signal: any)
	VFXContext.runtime():bind(signal)
end

function VFXContext.reset()
	if runtime then
		runtime:clear()
	end
	if pool then
		pool:clear()
	end
	if anchor then
		anchor:Destroy()
	end
	pool, runtime, anchor, root = nil, nil, nil, nil
end

return VFXContext
