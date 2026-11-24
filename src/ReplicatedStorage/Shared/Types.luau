--!strict
-- Tipos del modelo de datos de NEXORA.
-- Regla: SpeciesDefinition (Config/Species) es compartida e inmutable;
--        PetInstance es la criatura individual de un jugador (persistida en su perfil).

export type FormId = "Brote" | "Tallado"
export type StatId = "VID" | "ATQ" | "DEF" | "ESE" | "VEL"
export type Stats = { VID: number, ATQ: number, DEF: number, ESE: number, VEL: number }

export type AcquisitionSource = {
	kind: string, -- "Starter" | "Rescue" | "Breeding" | "Vitrina" | "Chest" | "Event" | "Dev"
	ref: string?,
	at: number,
}

export type PetTraits = {
	veta: string, -- color/material (Fase 2+)
	temple: string, -- "Neutro" en Fase 1
	don: string?,
	goldVein: boolean,
}

export type PetInstance = {
	id: string, -- único por cuenta: "U<userId>-<serial>"
	speciesId: string,
	form: FormId,
	level: number,
	xp: number, -- XP acumulada dentro del nivel actual
	bond: number, -- puntos de Vínculo
	nickname: string?,
	acquired: AcquisitionSource,
	traits: PetTraits,
	lineage: { generation: number, parents: { string }? },
	lastPlayedAt: number,
	evolvedAt: number?,
	loadout: { string }?, -- ids de movimiento equipados (nil = predeterminado)
	stats: { battlesWon: number, battlesLost: number, timesFed: number },
}

export type HabitatState = {
	id: string,
	slots: { string | false },
	level: number,
	lastCollectAt: number, -- última liquidación de producción
	accrued: number, -- Monedas liquidadas pendientes de recoger
	bonusCoins: number, -- reserva inicial de la primera recogida
}

export type PendingReward = {
	id: string,
	bundleId: string?,
	title: string,
	currencies: { [string]: number },
	items: { [string]: number },
	petXp: number,
	petIds: { string },
	unlocks: { string },
	source: { kind: string, ref: string, battleId: string? },
	createdAt: number,
	-- Fase 2 (opcionales en perfiles v1 migrados)
	chests: { string }?,
	eggs: { string }?, -- especies (fijadas al crear la recompensa)
	decor: { string }?,
	titles: { string }?,
	frames: { string }?,
}

-- ===================== Fase 2 =====================

-- Registro del Álbum/Bestiario por especie (timestamps del servidor)
export type CollectionEntry = {
	seenAt: number?, -- visto (como Opaco o en el mundo)
	restoredAt: number?, -- Opaco restaurado
	broteAt: number?, -- carta del Brote obtenida
	talladoAt: number?, -- carta del Tallado obtenida
	count: number?, -- ejemplares obtenidos en total
}

-- Huevo: especie y rasgos fijados AL OBTENERLO (nunca se vuelve a sortear)
export type EggInstance = {
	id: string, -- "E<userId>-<serial>"
	speciesId: string,
	rarity: string,
	traits: PetTraits,
	source: AcquisitionSource,
	obtainedAt: number,
	state: "Stored" | "Incubating",
	slot: number?,
	startedAt: number?,
	readyAt: number?,
}

export type IncubatorSlot = { unlocked: boolean, eggId: string? }

-- Cofre: su contenido se fija al obtenerlo; abrirlo solo lo entrega
export type ChestInstance = {
	id: string, -- "C<userId>-<serial>"
	chestType: string,
	contents: { currencies: { [string]: number }, items: { [string]: number }, eggs: { { speciesId: string } } },
	source: AcquisitionSource,
	obtainedAt: number,
}

export type HistoryEntry = {
	kind: string, -- "Chest" | "Egg" | "Hatch" | "Quest" | "Stage" | "Reward"
	ref: string,
	rarity: string?,
	speciesId: string?,
	detail: string?,
	at: number,
	source: string,
}

export type QuestSlot = { questId: string, progress: number, target: number, coins: number, claimed: boolean }
export type QuestState = {
	day: number,
	daily: { QuestSlot },
	dailyBonusClaimed: boolean,
	week: number,
	weekly: QuestSlot?,
}

export type Profile = {
	schemaVersion: number,
	userId: number,
	createdAt: number,
	lastLoginAt: number,
	loginCount: number,
	playSeconds: number,
	currencies: { [string]: number },
	items: { [string]: number },
	pets: { [string]: PetInstance },
	nextPetSerial: number,
	companionPetId: string?,
	team: { string },
	inventoryCapacity: number,
	lots: { [string]: { unlocked: boolean, habitats: { [string]: HabitatState } } },
	story: {
		cleared: { [string]: { firstClearAt: number, wins: number } },
		repeatDay: number,
		repeatCount: number,
		-- Fase 2 (Acto I): estrellas por etapa, mejores turnos, premios por región/acto
		stars: { [string]: { boolean } },
		bestTurns: { [string]: number },
		regionRewards: { [string]: number },
		actRewards: { [string]: number },
		treasureAttempts: { [string]: number },
	},
	onboarding: { step: string, completed: boolean, introSkipped: boolean?, startedAt: number },
	unlocks: { [string]: number },
	rewards: { pending: { [string]: PendingReward }, ledger: { [string]: number }, ledgerOrder: { string } },
	firsts: { [string]: number },
	counters: { [string]: number },
	-- Fase 2
	collection: { [string]: CollectionEntry },
	eggs: { [string]: EggInstance },
	nextEggSerial: number,
	incubators: { IncubatorSlot },
	chests: { [string]: ChestInstance },
	nextChestSerial: number,
	history: { HistoryEntry },
	quests: QuestState,
	codex: { [string]: number },
	decor: { slots: { string | false }, owned: { [string]: number } },
	showcase: { string },
	titles: { owned: { [string]: number }, equipped: string? },
	frames: { owned: { [string]: number }, equipped: string? },
	guardians: { [string]: number }, -- Seres Sagrados restaurados (una copia por cuenta)
	-- v3
	achievements: { [string]: number }, -- logro → hora del servidor en que se cumplió
}

return {}
