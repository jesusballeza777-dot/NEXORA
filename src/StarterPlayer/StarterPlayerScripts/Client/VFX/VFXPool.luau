--!strict
-- Reutiliza emisores, attachments, beams, trails, luces, highlights, volúmenes y sonidos
-- en lugar de crearlos y destruirlos sin parar. Limpieza garantizada:
-- * release() apaga la instancia, la saca del árbol (Parent = nil) y la guarda;
-- * releaseOwner(dueño) devuelve de una vez todo lo de un aura o de un efecto;
-- * al soltar un Attachment o un volumen se sueltan antes sus hijos del pool;
-- * límites por clase: si se agotan, acquire devuelve nil y el efecto se omite.

local VFXPool = {}
VFXPool.__index = VFXPool

local DEFAULT_LIMITS: { [string]: number } = {
	ParticleEmitter = 160,
	Attachment = 240,
	Beam = 96,
	Trail = 24,
	PointLight = 8,
	Highlight = 12, -- Roblox dibuja como mucho 31 Highlight a la vez
	Part = 48, -- volúmenes invisibles de emisión (solo efectos de combate, nunca aura)
	Sound = 24,
}

export type Stats = { created: number, reused: number, active: number, free: number, lost: number }

export type Pool = typeof(setmetatable(
	{} :: {
		free: { [string]: { Instance } },
		active: { [Instance]: { className: string, owner: any? } },
		limits: { [string]: number },
		counts: { [string]: number },
		created: number,
		reused: number,
		lost: number,
	},
	VFXPool
))

function VFXPool.new(limits: { [string]: number }?): Pool
	local l = table.clone(DEFAULT_LIMITS)
	for k, v in pairs(limits or {}) do
		l[k] = v
	end
	return setmetatable({
		free = {},
		active = {},
		limits = l,
		counts = {},
		created = 0,
		reused = 0,
		lost = 0,
	}, VFXPool)
end

local function fresh(className: string): Instance
	local inst = Instance.new(className)
	if inst:IsA("BasePart") then
		local p = inst :: BasePart
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = Vector3.new(0.2, 0.2, 0.2)
	end
	return inst
end

-- Apaga lo que pueda seguir visible o sonando
local function quiet(inst: Instance)
	if inst:IsA("ParticleEmitter") then
		inst.Enabled = false
		pcall(function()
			(inst :: ParticleEmitter):Clear()
		end)
	elseif inst:IsA("Beam") or inst:IsA("Trail") then
		local ribbon = inst :: any
		ribbon.Enabled = false
		-- Soltar las referencias (Lune no admite nil en propiedades Ref; Roblox sí)
		pcall(function()
			ribbon.Attachment0 = nil
			ribbon.Attachment1 = nil
		end)
	elseif inst:IsA("Light") then
		inst.Enabled = false
	elseif inst:IsA("Highlight") then
		inst.Enabled = false
		pcall(function()
			(inst :: Highlight).Adornee = nil
		end)
	elseif inst:IsA("Sound") then
		pcall(function()
			(inst :: Sound):Stop()
		end)
	end
end

function VFXPool.acquire(self: Pool, className: string, parent: Instance?, owner: any?): Instance?
	local list = self.free[className]
	local inst: Instance? = nil
	if list and #list > 0 then
		inst = table.remove(list)
		self.reused += 1
	else
		local count = self.counts[className] or 0
		if count >= (self.limits[className] or 64) then
			return nil
		end
		inst = fresh(className)
		self.counts[className] = count + 1
		self.created += 1
	end
	local i = inst :: Instance
	self.active[i] = { className = className, owner = owner }
	if parent then
		i.Parent = parent
	end
	return i
end

function VFXPool.release(self: Pool, inst: Instance?)
	if not inst then
		return
	end
	local rec = self.active[inst]
	if not rec then
		return
	end
	-- Primero los hijos que también son del pool (emisores dentro de un attachment)
	for _, child in ipairs(inst:GetChildren()) do
		if self.active[child] then
			self:release(child)
		end
	end
	self.active[inst] = nil
	quiet(inst)
	local ok = pcall(function()
		inst.Parent = nil
	end)
	if not ok then
		-- La instancia se destruyó por fuera (el modelo se borró sin soltar): se descarta
		self.lost += 1
		self.counts[rec.className] = math.max(0, (self.counts[rec.className] or 1) - 1)
		return
	end
	local list = self.free[rec.className]
	if not list then
		list = {}
		self.free[rec.className] = list
	end
	table.insert(list, inst)
end

function VFXPool.releaseOwner(self: Pool, owner: any)
	local mine: { Instance } = {}
	for inst, rec in pairs(self.active) do
		if rec.owner == owner then
			table.insert(mine, inst)
		end
	end
	for _, inst in ipairs(mine) do
		self:release(inst)
	end
end

function VFXPool.ownedBy(self: Pool, owner: any): number
	local n = 0
	for _, rec in pairs(self.active) do
		if rec.owner == owner then
			n += 1
		end
	end
	return n
end

function VFXPool.stats(self: Pool): Stats
	local active, free = 0, 0
	for _ in pairs(self.active) do
		active += 1
	end
	for _, list in pairs(self.free) do
		free += #list
	end
	return { created = self.created, reused = self.reused, active = active, free = free, lost = self.lost }
end

-- Destruye todo lo guardado (al salir del juego o en pruebas)
function VFXPool.clear(self: Pool)
	for inst in pairs(self.active) do
		pcall(function()
			inst:Destroy()
		end)
	end
	for _, list in pairs(self.free) do
		for _, inst in ipairs(list) do
			inst:Destroy()
		end
	end
	self.active = {}
	self.free = {}
	self.counts = {}
end

return VFXPool
