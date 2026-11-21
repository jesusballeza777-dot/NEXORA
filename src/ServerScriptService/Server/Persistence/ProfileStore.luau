--!strict
-- Almacén de perfiles con bloqueo de sesión sobre un backend tipo UpdateAsync.
--
-- Garantías:
-- * Un perfil solo puede estar abierto por un servidor (jobId) a la vez. Si otro
--   servidor lo tiene y su bloqueo no ha caducado, la carga reintenta y luego falla.
-- * Un guardado solo se escribe si este servidor sigue siendo el dueño del bloqueo;
--   si lo perdió, se marca lockLost y NO se sobrescribe nada (evita duplicaciones).
-- * Todas las escrituras usan update() (UpdateAsync en Roblox): nunca SetAsync.
-- * Migraciones y validación al cargar; validación antes de guardar.
--
-- Backend: { update: (self, key, transform: (old: any?) -> any?) -> (any?, string?) }
--   transform devuelve nil para cancelar la escritura.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local ProfileSchema = require(script.Parent.Parent.Domain.ProfileSchema)
local Freeze = require(Shared.Util.Freeze)
local Types = require(Shared.Types)

export type Backend = {
	update: (self: any, key: string, transform: (old: any?) -> any?) -> (any?, string?),
}

export type Session = {
	userId: number,
	key: string,
	data: Types.Profile,
	loadedAt: number,
	lastSavedAt: number,
	isNew: boolean,
	lockLost: boolean,
	released: boolean,
	saving: boolean,
	saveQueued: boolean,
}

export type Options = {
	backend: Backend,
	jobId: string,
	clock: () -> number,
	wait: ((seconds: number) -> ())?,
	lockTimeout: number?,
	maxLoadAttempts: number?,
	keyPrefix: string?,
}

local ProfileStore = {}
ProfileStore.__index = ProfileStore

export type ProfileStore = typeof(setmetatable(
	{} :: {
		backend: Backend,
		jobId: string,
		clock: () -> number,
		wait: (seconds: number) -> (),
		lockTimeout: number,
		maxLoadAttempts: number,
		keyPrefix: string,
	},
	ProfileStore
))

function ProfileStore.new(opts: Options): ProfileStore
	return setmetatable({
		backend = opts.backend,
		jobId = opts.jobId,
		clock = opts.clock,
		wait = opts.wait or function(_s: number) end,
		lockTimeout = opts.lockTimeout or 1800,
		maxLoadAttempts = opts.maxLoadAttempts or 5,
		keyPrefix = opts.keyPrefix or "Player_",
	}, ProfileStore)
end

function ProfileStore.keyFor(self: ProfileStore, userId: number): string
	return self.keyPrefix .. tostring(userId)
end

function ProfileStore.load(self: ProfileStore, userId: number): (Session?, string?)
	local key = self:keyFor(userId)
	local lastErr = "Unknown"
	for attempt = 1, self.maxLoadAttempts do
		local now = self.clock()
		local blocked, isNew, invalid = false, false, nil :: string?
		local loaded: any = nil
		local _, err = self.backend:update(key, function(old: any?)
			blocked, isNew, invalid, loaded = false, false, nil, nil
			local record = old or { meta = {}, data = nil }
			record.meta = record.meta or {}
			local lock = record.meta.lock
			if lock and lock.jobId ~= self.jobId and (now - (lock.at or 0)) < self.lockTimeout then
				blocked = true
				return nil
			end
			if record.data == nil then
				record.data = ProfileSchema.new(userId, now)
				isNew = true
			else
				local ok, migrated = pcall(ProfileSchema.migrate, record.data, now)
				if not ok then
					invalid = "MigrationFailed"
					return nil
				end
				record.data = migrated
			end
			local valid, why = ProfileSchema.validate(record.data)
			if not valid then
				invalid = "InvalidProfile:" .. tostring(why)
				return nil
			end
			record.meta.lock = { jobId = self.jobId, at = now }
			record.meta.writes = (record.meta.writes or 0) + 1
			record.meta.updatedAt = now
			loaded = record
			return record
		end)
		if invalid then
			-- Un perfil corrupto no se sobrescribe jamás: se bloquea la entrada y se registra.
			return nil, invalid
		end
		if err then
			lastErr = "BackendError:" .. tostring(err)
		elseif blocked then
			lastErr = "SessionLocked"
		elseif loaded then
			return {
				userId = userId,
				key = key,
				data = Freeze.copy(loaded.data),
				loadedAt = now,
				lastSavedAt = now,
				isNew = isNew,
				lockLost = false,
				released = false,
				saving = false,
				saveQueued = false,
			},
				nil
		end
		if attempt < self.maxLoadAttempts then
			self.wait(math.min(2 ^ attempt, 10))
		end
	end
	return nil, lastErr
end

-- Guarda el perfil. release = true libera el bloqueo (salida del jugador / cierre).
function ProfileStore.save(self: ProfileStore, session: Session, release: boolean?): (boolean, string?)
	if session.released then
		return false, "AlreadyReleased"
	end
	if session.lockLost then
		return false, "LockLost"
	end
	if session.saving then
		session.saveQueued = true
		return false, "SaveInProgress"
	end
	local valid, why = ProfileSchema.validate(session.data)
	if not valid then
		return false, "InvalidProfile:" .. tostring(why)
	end
	session.saving = true
	local now = self.clock()
	local lost = false
	local snapshot = Freeze.copy(session.data)
	local _, err = self.backend:update(session.key, function(old: any?)
		lost = false
		if not old or not old.meta or not old.meta.lock or old.meta.lock.jobId ~= self.jobId then
			lost = true
			return nil
		end
		old.data = snapshot
		old.meta.lock = if release then nil else { jobId = self.jobId, at = now }
		old.meta.writes = (old.meta.writes or 0) + 1
		old.meta.updatedAt = now
		return old
	end)
	session.saving = false
	if err then
		return false, "BackendError:" .. tostring(err)
	end
	if lost then
		session.lockLost = true
		return false, "LockLost"
	end
	session.lastSavedAt = now
	if release then
		session.released = true
	end
	if session.saveQueued and not release then
		session.saveQueued = false
		return self:save(session, false)
	end
	return true, nil
end

-- Guardado con reintentos para la salida del jugador y BindToClose.
function ProfileStore.saveWithRetry(
	self: ProfileStore,
	session: Session,
	release: boolean,
	attempts: number?
): (boolean, string?)
	local lastErr: string? = nil
	for i = 1, attempts or 4 do
		local ok, err = self:save(session, release)
		if ok then
			return true, nil
		end
		lastErr = err
		if err == "LockLost" or err == "AlreadyReleased" or (err and string.find(err, "InvalidProfile")) then
			return false, err
		end
		self.wait(math.min(2 ^ i, 8))
	end
	return false, lastErr
end

return ProfileStore
