--!strict
-- Reproduce señales de Config/AudioCues. Solo suena una señal con assetId aprobado: hoy
-- todas están en "Pending" sin ID, así que no suena nada (y está bien así).
-- * Espacial: con `at` (posición) o `parent` (pieza), RollOffMaxDistance de la señal.
-- * Variación de tono: PlaybackSpeed = 1 ± pitchVariance.
-- * Pool de voces: reutiliza Sound libres; con todas ocupadas roba la más antigua que no
--   esté en bucle. Ningún Sound se crea si la señal no tiene audio.
-- Los controladores de efectos y de combate lo llaman en sus fases (CombatVFXController,
-- EvolutionVFXController, BattleController, WorldController).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local AudioCues = require(Config:WaitForChild("AudioCues"))

local VFXContext = require(script.Parent.Parent.VFX.VFXContext)

local SoundController = {}
SoundController.__index = SoundController

type Voice = { sound: Sound, att: Attachment?, busyUntil: number, looped: boolean, cue: string, started: number }

export type Options = {
	cues: { [string]: any }?,
	now: (() -> number)?,
	rng: any?, -- objeto con NextNumber(min, max) (Random)
	maxVoices: number?,
	root: Instance?, -- dónde cuelgan los sonidos (por defecto, una carpeta en Workspace)
}

function SoundController.new(opts: Options?): any
	local o: Options = opts or {}
	return setmetatable({
		cues = o.cues or AudioCues.ById,
		now = o.now or os.clock,
		rng = o.rng or Random.new(),
		maxVoices = o.maxVoices or 16,
		root = o.root,
		voices = {} :: { Voice },
		volume = table.clone(AudioCues.CategoryVolume :: any),
		skipped = 0,
		played = 0,
	}, SoundController)
end

local shared: any = nil
function SoundController.shared(): any
	if not shared then
		shared = SoundController.new()
	end
	return shared
end

local function folder(self: any): Instance
	if self.root then
		return self.root
	end
	local f = Instance.new("Folder")
	f.Name = "NexoSounds"
	f.Parent = workspace
	self.root = f
	return f
end

local function voiceFor(self: any, now: number): Voice?
	for _, v in ipairs(self.voices) do
		if not v.looped and v.busyUntil <= now then
			return v
		end
	end
	if #self.voices < self.maxVoices then
		local s = Instance.new("Sound")
		s.Name = "NexoVoice"
		local v: Voice = { sound = s, att = nil, busyUntil = 0, looped = false, cue = "", started = 0 }
		table.insert(self.voices, v)
		return v
	end
	-- Todas ocupadas: se roba la más antigua que no esté en bucle
	local oldest: Voice? = nil
	for _, v in ipairs(self.voices) do
		if not v.looped and (oldest == nil or v.started < (oldest :: Voice).started) then
			oldest = v
		end
	end
	return oldest
end

-- Reproduce una señal. Devuelve el Sound o nil (sin audio aprobado, señal desconocida o
-- sin voces libres).
function SoundController.play(
	self: any,
	id: string,
	opts: { at: Vector3?, parent: Instance?, volume: number? }?
): Sound?
	local cue = self.cues[id]
	if not cue or not cue.assetId then
		self.skipped += 1
		return nil
	end
	local now = self.now()
	local v = voiceFor(self, now)
	if not v then
		self.skipped += 1
		return nil
	end
	local voice = v :: Voice
	local s = voice.sound
	pcall(function()
		s:Stop()
	end)
	local o = opts or {}
	s.SoundId = cue.assetId
	s.Volume = cue.volume * (self.volume[cue.category] or 1) * (o.volume or 1)
	s.Looped = cue.loop == true
	local pv = cue.pitchVariance or 0
	s.PlaybackSpeed = if pv > 0 then 1 + self.rng:NextNumber(-pv, pv) else 1
	-- Espacial si la señal lo pide y hay posición o pieza
	if cue.rollOffMaxDistance and (o.at or o.parent) then
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = cue.rollOffMaxDistance
		if o.parent then
			s.Parent = o.parent
		else
			if not voice.att then
				local att = Instance.new("Attachment")
				att.Name = "NexoVoiceAt"
				voice.att = att
			end
			-- El ancla de efectos está en el origen: el CFrame del attachment es el del mundo
			local att = voice.att :: Attachment
			att.Parent = VFXContext.anchor()
			att.CFrame = CFrame.new(o.at :: Vector3)
			s.Parent = att
		end
	else
		s.Parent = folder(self)
	end
	voice.looped = cue.loop == true
	voice.cue = id
	voice.started = now
	voice.busyUntil = now + (cue.duration or 3) / s.PlaybackSpeed
	pcall(function()
		s:Play()
	end)
	self.played += 1
	return s
end

function SoundController.stop(self: any, id: string?)
	for _, v in ipairs(self.voices) do
		if id == nil or v.cue == id then
			pcall(function()
				v.sound:Stop()
			end)
			v.looped = false
			v.busyUntil = 0
		end
	end
end

function SoundController.setCategoryVolume(self: any, category: string, value: number)
	self.volume[category] = math.clamp(value, 0, 1)
end

function SoundController.stats(self: any): { voices: number, played: number, skipped: number }
	return { voices = #self.voices, played = self.played, skipped = self.skipped }
end

return SoundController
